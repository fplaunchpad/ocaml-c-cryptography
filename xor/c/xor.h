#ifndef XOR_H
#define XOR_H

void xor_encrypt(char *message,
                 char *key,
                 char *output,
                 int msg_len,
                 int key_len);

void xor_decrypt(char *ciphertext,
                 char *key,
                 char *output,
                 int cipher_len,
                 int key_len);

#endif