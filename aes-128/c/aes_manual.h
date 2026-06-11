#ifndef AES_MANUAL_H
#define AES_MANUAL_H

#include <stdint.h>

void init_inv_sbox(void);

void key_expansion(uint8_t key[16],
                   uint8_t words[44][4]);

void aes128_encrypt(uint8_t state[4][4],
                    uint8_t words[44][4]);

void aes128_decrypt(uint8_t state[4][4],
                    uint8_t words[44][4]);

void aes_encrypt_buffer(uint8_t *input,
                        uint8_t *output,
                        long len,
                        uint8_t words[44][4]);

void aes_decrypt_buffer(uint8_t *input,
                        uint8_t *output,
                        long len,
                        uint8_t words[44][4]);                   

#endif