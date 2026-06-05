#include "xor.h"

void xor_encrypt(char *message,
                 char *key,
                 char *output,
                 int msg_len,
                 int key_len)
{
    for(int i = 0; i < msg_len; i++)
    {
        output[i] = message[i] ^ key[i % key_len];
    }
}

void xor_decrypt(char *ciphertext,
                 char *key,
                 char *output,
                 int cipher_len,
                 int key_len)
{
    for(int i = 0; i < cipher_len; i++)
    {
        output[i] = ciphertext[i] ^ key[i % key_len];
    }
}