// aes.h

#include <stdint.h>

void key_expansion(uint8_t words[44][4]);

void aes128_encrypt(uint8_t state[4][4],
                    uint8_t words[44][4]);

void aes128_decrypt(uint8_t state[4][4],
                    uint8_t words[44][4]);