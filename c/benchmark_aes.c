#include <stdio.h>
#include <time.h>
#include <stdint.h>
#include "aes.h"

double get_time()
{
    return (double)clock() / CLOCKS_PER_SEC;
}

int main()
{
    uint8_t state[4][4] = {
        {0x32,0x43,0xF6,0xA8},
        {0x88,0x5A,0x30,0x8D},
        {0x31,0x31,0x98,0xA2},
        {0xE0,0x37,0x07,0x34}
    };

    uint8_t words[44][4];

    key_expansion(words);

    double start = get_time();
    
    for(int i = 0; i < 1000000; i++)
    {
        uint8_t state[4][4] = {
            {0x32,0x43,0xF6,0xA8},
            {0x88,0x5A,0x30,0x8D},
            {0x31,0x31,0x98,0xA2},
            {0xE0,0x37,0x07,0x34}
        };
    
        aes128_encrypt(state, words);
    }

    double end = get_time();

    printf("AES encryptions: 1000000\n");
    printf("Time: %.6f sec\n", end - start);

    start = get_time();

    for(int i = 0; i < 1000000; i++)
    {
        uint8_t state[4][4] = {
            {0xB8,0x22,0xFE,0x47},
            {0x6F,0x13,0xF2,0xCA},
            {0x82,0x11,0xED,0x45},
            {0xE3,0x37,0x58,0x82}
        };

        aes128_decrypt(state, words);
    }

    end = get_time();

    printf("AES decryptions: 1000000\n");
    printf("Time: %.6f sec\n", end - start);

    return 0;
}