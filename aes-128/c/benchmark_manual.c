#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <time.h>

#include "aes_manual.h"

int main(int argc, char *argv[])
{
    if(argc != 2)
    {
        printf("Usage: %s <input_file>\n", argv[0]);
        return 1;
    }

    char *input_file = argv[1];

    FILE *fp = fopen(input_file, "rb");

    if(fp == NULL)
    {
        printf("Cannot open input file\n");
        return 1;
    }

    fseek(fp, 0, SEEK_END);
    long msg_len = ftell(fp);
    rewind(fp);

    long padded_len =
        ((msg_len + 15) / 16) * 16;

    uint8_t *message =
        calloc(padded_len, 1);

    if(message == NULL)
    {
        printf("Memory allocation failed\n");
        fclose(fp);
        return 1;
    }

    if(fread(message, 1, msg_len, fp) != (size_t)msg_len)
    {
        printf("Failed to read input file\n");
        fclose(fp);
        free(message);
        return 1;
    }

    fclose(fp);

    FILE *kf = fopen("../benchmarks/key.txt", "rb");

    if(kf == NULL)
    {
        printf("Cannot open key file\n");
        free(message);
        return 1;
    }

    uint8_t key[16];

    if(fread(key, 1, 16, kf) != 16)
    {
        printf("Failed to read key file\n");
        fclose(kf);
        free(message);
        return 1;
    }

    fclose(kf);

    init_inv_sbox();

    uint8_t words[44][4];

    key_expansion(key, words);

    uint8_t *encrypted =
        malloc(padded_len);

    uint8_t *decrypted =
        malloc(padded_len);

    if(encrypted == NULL ||
    decrypted == NULL)
    {
        printf("Memory allocation failed\n");

        free(message);
        free(encrypted);
        free(decrypted);

        return 1;
    }

    clock_t enc_start = clock();

    aes_encrypt_buffer(
        message,
        encrypted,
        padded_len,
        words
    );

    clock_t enc_end = clock();

    clock_t dec_start = clock();

    aes_decrypt_buffer(
        encrypted,
        decrypted,
        padded_len,
        words
    );

    clock_t dec_end = clock();

    int ok = 1;

    for(long i = 0; i < msg_len; i++)
    {
        if(message[i] != decrypted[i])
        {
            ok = 0;
            break;
        }
    }

    double enc_time =
        (double)(enc_end - enc_start)
        / CLOCKS_PER_SEC;

    double dec_time =
        (double)(dec_end - dec_start)
        / CLOCKS_PER_SEC;

    double enc_mb =
        ((double)msg_len / (1024.0 * 1024.0))
        / enc_time;

    double dec_mb =
        ((double)msg_len / (1024.0 * 1024.0))
        / dec_time;
    
    printf("Message length      : %ld bytes\n",
        msg_len);

    printf("Encryption time     : %.6f sec\n",
        enc_time);

    printf("Decryption time     : %.6f sec\n",
        dec_time);

    printf("Encryption speed    : %.2f MB/s\n",
        enc_mb);

    printf("Decryption speed    : %.2f MB/s\n",
        dec_mb);

    printf("Verification        : %s\n",
        ok ? "PASSED" : "FAILED");

    free(message);
    free(encrypted);
    free(decrypted);

    return 0;
}