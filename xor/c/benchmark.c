#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "xor.h"

int main(int argc, char *argv[])
{
    if(argc != 2)
    {
        printf("Usage: %s <input_file>\n", argv[0]);
        return 1;
    }

    char *input_file = argv[1];
    
    FILE *fp = fopen(input_file, "rb");

    if (fp == NULL)
    {
        printf("Cannot open input file\n");
        return 1;
    }

    fseek(fp, 0, SEEK_END);
    long msg_len = ftell(fp);
    rewind(fp);

    char *message = malloc(msg_len);

    if (fread(message, 1, msg_len, fp) != (size_t)msg_len)
    {
        printf("Failed to read input file\n");
        fclose(fp);
        free(message);
        return 1;
    }
    
    fclose(fp);

    FILE *kf = fopen("../benchmarks/key.txt", "rb");

    if (kf == NULL)
    {
        printf("Cannot open key file\n");
        free(message);
        return 1;
    }

    fseek(kf, 0, SEEK_END);
    long key_len = ftell(kf);
    rewind(kf);

    char *key = malloc(key_len);

    if (fread(key, 1, key_len, kf) != (size_t)key_len)
    {
        printf("Failed to read key file\n");
        fclose(kf);
        free(message);
        free(key);
        return 1;
    }
    
    fclose(kf);

    while (key_len > 0 &&
           (key[key_len - 1] == '\n' ||
            key[key_len - 1] == '\r'))
    {
        key_len--;
    }

    if (key_len == 0)
    {
        printf("Key file is empty\n");
        free(message);
        free(key);
        return 1;
    }

    char *encrypted = malloc(msg_len);
    char *decrypted = malloc(msg_len);

    clock_t enc_start = clock();

    for(int i = 0; i < 10; i++)
    {
        xor_encrypt(
            message,
            key,
            encrypted,
            msg_len,
            key_len
        );
    }

    clock_t enc_end = clock();

    FILE *cf =
        fopen("../benchmarks/ciphertext.bin", "wb");

    fwrite(
        encrypted,
        1,
        msg_len,
        cf
    );

    fclose(cf);

    clock_t dec_start = clock();

    for(int i = 0; i < 10; i++)
    {
        xor_decrypt(
            encrypted,
            key,
            decrypted,
            msg_len,
            key_len
        );
    }

    clock_t dec_end = clock();

    FILE *df =
        fopen("../benchmarks/decrypted.txt", "wb");

    fwrite(
        decrypted,
        1,
        msg_len,
        df
    );

    fclose(df);

    int ok = 1;

    for (long i = 0; i < msg_len; i++)
    {
        if (message[i] != decrypted[i])
        {
            ok = 0;
            break;
        }
    }

    double enc_time =
        ((double)(enc_end - enc_start)
        / CLOCKS_PER_SEC)/10.0;

    double dec_time =
        ((double)(dec_end - dec_start)
        / CLOCKS_PER_SEC)/10.0;

    double enc_mb =
        ((double)msg_len / (1024.0 * 1024.0))
        / enc_time;

    double dec_mb =
        ((double)msg_len / (1024.0 * 1024.0))
        / dec_time;

    printf("Message length      : %ld bytes\n",
           msg_len);

    printf("Key length          : %ld bytes\n",
           key_len);

    printf("Encryption time     : %.6f sec\n",
           enc_time);

    printf("Decryption time     : %.6f sec\n",
           dec_time);

    printf("Encryption speed    : %.2f MB/s\n", enc_mb);

    printf("Decryption speed    : %.2f MB/s\n", dec_mb);

    printf("Verification        : %s\n",
           ok ? "PASSED" : "FAILED");

    free(message);
    free(key);
    free(encrypted);
    free(decrypted);

    return 0;
}