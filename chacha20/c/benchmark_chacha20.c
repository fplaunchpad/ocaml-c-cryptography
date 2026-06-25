#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define EXPORT extern
#include "chacha20.h"

static double get_time(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec + ts.tv_nsec / 1e9;
}

static int read_file(const char *path, unsigned char *buf, size_t expected_len) {
    FILE *fp = fopen(path, "rb");
    if (!fp) { perror(path); return 0; }
    size_t n = fread(buf, 1, expected_len, fp);
    fclose(fp);
    if (n != expected_len) {
        fprintf(stderr, "%s: expected %zu bytes, got %zu\n", path, expected_len, n);
        return 0;
    }
    return 1;
}

int main(int argc, char *argv[]) {
    if (argc != 4) {
        fprintf(stderr, "Usage: %s <input_file> <key_file> <nonce_file>\n", argv[0]);
        return 1;
    }

    /* Read input */
    FILE *fp = fopen(argv[1], "rb");
    if (!fp) { perror(argv[1]); return 1; }
    fseek(fp, 0, SEEK_END);
    long msg_len = ftell(fp);
    rewind(fp);
    unsigned char *message = malloc(msg_len);
    if (!message) { fprintf(stderr, "malloc failed\n"); fclose(fp); return 1; }
    if (fread(message, 1, msg_len, fp) != (size_t)msg_len) {
        fprintf(stderr, "fread failed\n"); free(message); fclose(fp); return 1;
    }
    fclose(fp);

    /* Read key (32 bytes) and nonce (12 bytes) from files */
    uint8_t key[32], nonce[12];
    if (!read_file(argv[2], key, 32) || !read_file(argv[3], nonce, 12)) {
        free(message);
        return 1;
    }

    const uint64_t counter = 0;

    unsigned char *ciphertext = malloc(msg_len);
    unsigned char *decrypted  = malloc(msg_len);
    if (!ciphertext || !decrypted) {
        fprintf(stderr, "malloc failed\n");
        free(message);
        return 1;
    }

    chacha20_ctx ctx;

    /* Timed encryption */
    chacha20_init(&ctx, key, 32, nonce, 12, counter);
    double enc_start = get_time();
    chacha20_transform(&ctx, message, ciphertext, msg_len);
    double enc_end = get_time();

    /* Timed decryption — ChaCha20 is symmetric, same op with same key/nonce/counter */
    chacha20_init(&ctx, key, 32, nonce, 12, counter);
    double dec_start = get_time();
    chacha20_transform(&ctx, ciphertext, decrypted, msg_len);
    double dec_end = get_time();

    /* Correctness check — outside timed sections */
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

    free(message);
    free(ciphertext);
    free(decrypted);
    return 0;
}
