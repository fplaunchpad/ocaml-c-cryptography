#include<stdio.h>
#include<string.h>
#include<stdlib.h>

void xor_encrypt(char *message,
                 char *key,
                 char *output,
                 int msg_len,
                 int key_len){

    for(int i = 0; i < msg_len; i++){
        output[i] = message[i] ^ key[i % key_len];
    }
}

int main(){

    char base[] =
        "CryptographyAndFunctionalProgrammingResearch123";

    int repeat = 100000;

    int base_len = strlen(base);

    int total_len = repeat * base_len;

    char *message = malloc(total_len);

    for(int i = 0; i < repeat; i++){
        memcpy(
            message + i * base_len,
            base,
            base_len
        );
    }

    char key[] = "securekey";

    int key_len = strlen(key);

    char *encrypted = malloc(total_len);
    char *decrypted = malloc(total_len);

    xor_encrypt(
        message,
        key,
        encrypted,
        total_len,
        key_len
    );

    xor_encrypt(
        encrypted,
        key,
        decrypted,
        total_len,
        key_len
    );

    int ok = 1;

    for(int i = 0; i < total_len; i++){

        if(message[i] != decrypted[i]){
            ok = 0;
            break;
        }
    }

    printf("Message length: %d\n", total_len);

    printf("Encryption completed\n");

    printf("Decryption correct: %s\n",
           ok ? "true" : "false");

    free(message);
    free(encrypted);
    free(decrypted);

    return 0;
}