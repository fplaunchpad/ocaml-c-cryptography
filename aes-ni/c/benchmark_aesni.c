#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define EXPORT extern
#include "aesni.h"

static double get_time(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec + ts.tv_nsec / 1e9;
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <input_file>\n", argv[0]);
        return 1;
    }

    if (!aesni_check_available()) {
        fprintf(stderr, "AES-NI not supported on this CPU\n");
        return 1;
    }

    FILE *fp = fopen(argv[1], "rb");
    if (!fp) {
        perror("fopen");
        return 1;
    }

    fseek(fp, 0, SEEK_END);
    long msg_len = ftell(fp);
    rewind(fp);

    long padded_len = ((msg_len + 15) / 16) * 16;

    unsigned char *message = calloc(padded_len, 1);
    if (!message) {
        fprintf(stderr, "Memory allocation failed\n");
        fclose(fp);
        return 1;
    }
    fread(message, 1, msg_len, fp);
    fclose(fp);

    /* Fixed 16-byte key for AES-128 */
    static const unsigned char key[16] = {
        0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
        0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f
    };

    /* Key schedule buffers: 15 round keys × 16 bytes covers AES-128/192/256 */
    unsigned char ckey_enc[15 * 16];
    unsigned char ckey_dec[15 * 16];

    int nr_enc = aesniKeySetupEnc(ckey_enc, key, 128);
    int nr_dec = aesniKeySetupDec(ckey_dec, key, 128);

    unsigned char *encrypted = malloc(padded_len);
    unsigned char *decrypted = malloc(padded_len);
    if (!encrypted || !decrypted) {
        fprintf(stderr, "Memory allocation failed\n");
        free(message);
        return 1;
    }

    double enc_start = get_time();
    for (long i = 0; i < padded_len; i += 16)
        aesniEncrypt(ckey_enc, nr_enc, message + i, encrypted + i);
    double enc_end = get_time();

    double dec_start = get_time();
    for (long i = 0; i < padded_len; i += 16)
        aesniDecrypt(ckey_dec, nr_dec, encrypted + i, decrypted + i);
    double dec_end = get_time();

    int ok = (memcmp(message, decrypted, msg_len) == 0);

    double enc_time = enc_end - enc_start;
    double dec_time = dec_end - dec_start;
    double size_mb  = (double)msg_len / (1024.0 * 1024.0);

    printf("Message length      : %ld bytes\n",  msg_len);
    printf("Encryption time     : %.6f sec\n",   enc_time);
    printf("Decryption time     : %.6f sec\n",   dec_time);
    printf("Encryption speed    : %.2f MB/s\n",  size_mb / enc_time);
    printf("Decryption speed    : %.2f MB/s\n",  size_mb / dec_time);
    printf("Verification        : %s\n",          ok ? "PASSED" : "FAILED");

    free(message);
    free(encrypted);
    free(decrypted);
    return 0;
}
