#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "chacha20_simd.h"

static double get_time(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec + ts.tv_nsec / 1e9;
}

static int read_file(const char *path, unsigned char **buf, long *len)
{
    FILE *fp = fopen(path, "rb");
    if (!fp) { perror(path); return 0; }
    fseek(fp, 0, SEEK_END);
    *len = ftell(fp);
    rewind(fp);
    *buf = malloc(*len);
    if (!*buf) { fclose(fp); return 0; }
    if ((long)fread(*buf, 1, *len, fp) != *len) { fclose(fp); free(*buf); return 0; }
    fclose(fp);
    return 1;
}

/* ---- RFC 8439 §2.3.2 correctness test ------------------------------------ */
/*
 * RFC 7539 §2.3.2 test vector (corrected in RFC 8439):
 *   key   = 00 01 02 ... 1f  (32 bytes)
 *   nonce = 00 00 00 09 00 00 00 4a 00 00 00 00  (12 bytes, IETF)
 *   counter = 1
 * Expected keystream block (64 bytes, verified against OpenSSL and OxCaml):
 */
static const uint8_t rfc_key[32] = {
    0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,
    0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f,
    0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,
    0x18,0x19,0x1a,0x1b,0x1c,0x1d,0x1e,0x1f
};
static const uint8_t rfc_nonce[12] = {
    0x00,0x00,0x00,0x09, 0x00,0x00,0x00,0x4a, 0x00,0x00,0x00,0x00
};
static const uint8_t rfc_expected[64] = {
    0x10,0xf1,0xe7,0xe4, 0xd1,0x3b,0x59,0x15,
    0x50,0x0f,0xdd,0x1f, 0xa3,0x20,0x71,0xc4,
    0xc7,0xd1,0xf4,0xc7, 0x33,0xc0,0x68,0x03,
    0x04,0x22,0xaa,0x9a, 0xc3,0xd4,0x6c,0x4e,
    0xd2,0x82,0x64,0x46, 0x07,0x9f,0xaa,0x09,
    0x14,0xc2,0xd7,0x05, 0xd9,0x8b,0x02,0xa2,
    0xb5,0x12,0x9c,0xd1, 0xde,0x16,0x4e,0xb9,
    0xcb,0xd0,0x83,0xe8, 0xa2,0x50,0x3c,0x4e
};

static void run_rfc_test(void)
{
    chacha20_simd_ctx ctx;
    uint8_t got[64];

    chacha20_init(&ctx, rfc_key, 32, rfc_nonce, 12, 1);
    chacha20_extract(&ctx, got, 64);

    if (memcmp(got, rfc_expected, 64) != 0) {
        fprintf(stderr, "FAIL RFC 8439 §2.3.2 block test\n  got:      ");
        for (int i = 0; i < 64; i++) fprintf(stderr, "%02x", got[i]);
        fprintf(stderr, "\n  expected: ");
        for (int i = 0; i < 64; i++) fprintf(stderr, "%02x", rfc_expected[i]);
        fprintf(stderr, "\n");
        exit(1);
    }
    printf("RFC 8439 §2.3.2 block test: PASSED\n");
}

/* -------------------------------------------------------------------------- */

int main(int argc, char *argv[])
{
    run_rfc_test();

    if (argc != 4) {
        fprintf(stderr, "Usage: %s <input_file> <key_file> <nonce_file>\n", argv[0]);
        return 1;
    }

    unsigned char *message = NULL, *key_buf = NULL, *nonce_buf = NULL;
    long msg_len, key_len, nonce_len;

    if (!read_file(argv[1], &message,   &msg_len)  ||
        !read_file(argv[2], &key_buf,   &key_len)  ||
        !read_file(argv[3], &nonce_buf, &nonce_len))
        return 1;

    unsigned char *ciphertext = malloc(msg_len);
    unsigned char *decrypted  = malloc(msg_len);
    if (!ciphertext || !decrypted) { fprintf(stderr, "malloc failed\n"); return 1; }

    chacha20_simd_ctx ctx;

    /* Timed encryption */
    chacha20_init(&ctx, key_buf, (size_t)key_len, nonce_buf, (size_t)nonce_len, 0);
    double enc_start = get_time();
    chacha20_transform(&ctx, message, ciphertext, (size_t)msg_len);
    double enc_end = get_time();

    /* Timed decryption — ChaCha20 is symmetric */
    chacha20_init(&ctx, key_buf, (size_t)key_len, nonce_buf, (size_t)nonce_len, 0);
    double dec_start = get_time();
    chacha20_transform(&ctx, ciphertext, decrypted, (size_t)msg_len);
    double dec_end = get_time();

    int ok = (memcmp(message, decrypted, msg_len) == 0);

    double enc_time = enc_end - enc_start;
    double dec_time = dec_end - dec_start;
    double size_mb  = (double)msg_len / (1024.0 * 1024.0);

    printf("Message length      : %ld bytes\n", msg_len);
    printf("Encryption time     : %.6f sec\n",  enc_time);
    printf("Decryption time     : %.6f sec\n",  dec_time);
    printf("Encryption speed    : %.2f MB/s\n", size_mb / enc_time);
    printf("Decryption speed    : %.2f MB/s\n", size_mb / dec_time);
    printf("Correctness         : %s\n",         ok ? "PASSED" : "FAILED");

    free(message); free(key_buf); free(nonce_buf);
    free(ciphertext); free(decrypted);
    return 0;
}
