#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>

#include "rijndael-alg-fst.h"

double get_time() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec + tv.tv_usec / 1000000.0;
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        printf("Usage: %s <input_file>\n", argv[0]);
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

    long padded_len =
        ((msg_len + 15) / 16) * 16;

    unsigned char *message =
        calloc(padded_len, 1);

    fread(message, 1, msg_len, fp);
    fclose(fp);

    FILE *kf = fopen("../benchmarks/key.txt", "rb");

    if (!kf) {
        perror("key.txt");
        free(message);
        return 1;
    }

    unsigned char key[16];

    fread(key, 1, 16, kf);

    fclose(kf);

    u32 rk_enc[4 * (MAXNR + 1)];
    u32 rk_dec[4 * (MAXNR + 1)];

    int nr_enc =
        rijndaelKeySetupEnc(
            rk_enc,
            key,
            128);

    int nr_dec =
        rijndaelKeySetupDec(
            rk_dec,
            key,
            128);
            
        unsigned char *encrypted =
        malloc(padded_len);

    unsigned char *decrypted =
        malloc(padded_len);

    if (!encrypted || !decrypted) {
        printf("Memory allocation failed\n");
        free(message);
        return 1;
    }

    double enc_start = get_time();

    for (long i = 0; i < padded_len; i += 16) {
        rijndaelEncrypt(
            rk_enc,
            nr_enc,
            message + i,
            encrypted + i
        );
    }

    double enc_end = get_time();

    double dec_start = get_time();

    for (long i = 0; i < padded_len; i += 16) {
        rijndaelDecrypt(
            rk_dec,
            nr_dec,
            encrypted + i,
            decrypted + i
        );
    }

    double dec_end = get_time();

    int ok = 1;

    for (long i = 0; i < msg_len; i++) {
        if (message[i] != decrypted[i]) {
            ok = 0;
            break;
        }
    }
    
    double enc_time = enc_end - enc_start;
    double dec_time = dec_end - dec_start;

    double size_mb =
        (double)msg_len /
        (1024.0 * 1024.0);

    double enc_speed =
        size_mb / enc_time;

    double dec_speed =
        size_mb / dec_time;

    printf("Message length      : %ld bytes\n",
        msg_len);

    printf("Encryption time     : %.6f sec\n",
        enc_time);

    printf("Decryption time     : %.6f sec\n",
        dec_time);

    printf("Encryption speed    : %.2f MB/s\n",
        enc_speed);

    printf("Decryption speed    : %.2f MB/s\n",
        dec_speed);

    printf("Verification        : %s\n",
        ok ? "PASSED" : "FAILED");
        
    free(message);

    return 0;
}