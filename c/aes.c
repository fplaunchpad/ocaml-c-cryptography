#include <stdio.h>
#include <stdint.h>
#include "aes.h"

void print_state(uint8_t state[4][4]) {
    for(int i = 0; i < 4; i++) {
        for(int j = 0; j < 4; j++) {
            printf("%02X ", state[i][j]);
        }
        printf("\n");
    }
}

void add_round_key(uint8_t state[4][4], uint8_t key[4][4]) {
    for(int i = 0; i < 4; i++) {
        for(int j = 0; j < 4; j++) {
            state[i][j] ^= key[i][j];
        }
    }
}

static const uint8_t sbox[256] = {
0x63,0x7c,0x77,0x7b,0xf2,0x6b,0x6f,0xc5,
0x30,0x01,0x67,0x2b,0xfe,0xd7,0xab,0x76,

0xca,0x82,0xc9,0x7d,0xfa,0x59,0x47,0xf0,
0xad,0xd4,0xa2,0xaf,0x9c,0xa4,0x72,0xc0,

0xb7,0xfd,0x93,0x26,0x36,0x3f,0xf7,0xcc,
0x34,0xa5,0xe5,0xf1,0x71,0xd8,0x31,0x15,

0x04,0xc7,0x23,0xc3,0x18,0x96,0x05,0x9a,
0x07,0x12,0x80,0xe2,0xeb,0x27,0xb2,0x75,

0x09,0x83,0x2c,0x1a,0x1b,0x6e,0x5a,0xa0,
0x52,0x3b,0xd6,0xb3,0x29,0xe3,0x2f,0x84,

0x53,0xd1,0x00,0xed,0x20,0xfc,0xb1,0x5b,
0x6a,0xcb,0xbe,0x39,0x4a,0x4c,0x58,0xcf,

0xd0,0xef,0xaa,0xfb,0x43,0x4d,0x33,0x85,
0x45,0xf9,0x02,0x7f,0x50,0x3c,0x9f,0xa8,

0x51,0xa3,0x40,0x8f,0x92,0x9d,0x38,0xf5,
0xbc,0xb6,0xda,0x21,0x10,0xff,0xf3,0xd2,

0xcd,0x0c,0x13,0xec,0x5f,0x97,0x44,0x17,
0xc4,0xa7,0x7e,0x3d,0x64,0x5d,0x19,0x73,

0x60,0x81,0x4f,0xdc,0x22,0x2a,0x90,0x88,
0x46,0xee,0xb8,0x14,0xde,0x5e,0x0b,0xdb,

0xe0,0x32,0x3a,0x0a,0x49,0x06,0x24,0x5c,
0xc2,0xd3,0xac,0x62,0x91,0x95,0xe4,0x79,

0xe7,0xc8,0x37,0x6d,0x8d,0xd5,0x4e,0xa9,
0x6c,0x56,0xf4,0xea,0x65,0x7a,0xae,0x08,

0xba,0x78,0x25,0x2e,0x1c,0xa6,0xb4,0xc6,
0xe8,0xdd,0x74,0x1f,0x4b,0xbd,0x8b,0x8a,

0x70,0x3e,0xb5,0x66,0x48,0x03,0xf6,0x0e,
0x61,0x35,0x57,0xb9,0x86,0xc1,0x1d,0x9e,

0xe1,0xf8,0x98,0x11,0x69,0xd9,0x8e,0x94,
0x9b,0x1e,0x87,0xe9,0xce,0x55,0x28,0xdf,

0x8c,0xa1,0x89,0x0d,0xbf,0xe6,0x42,0x68,
0x41,0x99,0x2d,0x0f,0xb0,0x54,0xbb,0x16
};

uint8_t inv_sbox[256];

void init_inv_sbox()
{
    for(int i=0;i<256;i++)
        inv_sbox[sbox[i]] = i;
}

void sub_bytes(uint8_t state[4][4]) {
    for(int i = 0; i < 4; i++) {
        for(int j = 0; j < 4; j++) {
            state[i][j] = sbox[state[i][j]];
        }
    }
}

void inv_sub_bytes(uint8_t state[4][4])
{
    for(int i=0;i<4;i++)
    {
        for(int j=0;j<4;j++)
        {
            state[i][j] = inv_sbox[state[i][j]];
        }
    }
}

void shift_rows(uint8_t state[4][4]){
    uint8_t temp;

    // Row 1: No shift

    // Row 2: Shift left by 1
    temp = state[1][0];
    for(int j = 0; j < 3; j++) {
        state[1][j] = state[1][j + 1];
    }
    state[1][3] = temp;

    // Row 3: Shift left by 2
    uint8_t temp1 = state[2][0];
    uint8_t temp2 = state[2][1];
    for(int j = 0; j < 2; j++) {
        state[2][j] = state[2][j + 2];
    }
    state[2][2] = temp1;
    state[2][3] = temp2;

    // Row 4: Shift left by 3 (or right by 1)
    temp = state[3][3];
    for(int j = 3; j > 0; j--) {
        state[3][j] = state[3][j - 1];
    }
    state[3][0] = temp;
}

void inv_shift_rows(uint8_t state[4][4])
{
    uint8_t temp;

    // Row 1: no shift

    // Row 2: right shift by 1
    temp = state[1][3];

    for(int j=3;j>0;j--)
        state[1][j] = state[1][j-1];

    state[1][0] = temp;

    // Row 3: right shift by 2
    uint8_t temp1 = state[2][2];
    uint8_t temp2 = state[2][3];

    state[2][3] = state[2][1];
    state[2][2] = state[2][0];
    state[2][1] = temp2;
    state[2][0] = temp1;

    // Row 4: right shift by 3
    // same as left shift by 1

    temp = state[3][0];

    for(int j=0;j<3;j++)
        state[3][j] = state[3][j+1];

    state[3][3] = temp;
}

uint8_t xtime(uint8_t x) {
    if (x & 0x80)
        return (x << 1) ^ 0x1B;
    else
        return x << 1;
}

uint8_t mul2(uint8_t x) {
    return xtime(x);
}

uint8_t mul3(uint8_t x) {
    return xtime(x) ^ x;
}

uint8_t mul4(uint8_t x)
{
    return mul2(mul2(x));
}

uint8_t mul8(uint8_t x)
{
    return mul2(mul4(x));
}

uint8_t mul9(uint8_t x)
{
    return mul8(x) ^ x;
}

uint8_t mul11(uint8_t x)
{
    return mul8(x) ^ mul2(x) ^ x;
}

uint8_t mul13(uint8_t x)
{
    return mul8(x) ^ mul4(x) ^ x;
}

uint8_t mul14(uint8_t x)
{
    return mul8(x) ^ mul4(x) ^ mul2(x);
}

void mix_single_column(uint8_t col[4])
{
    uint8_t a = col[0];
    uint8_t b = col[1];
    uint8_t c = col[2];
    uint8_t d = col[3];

    col[0] = mul2(a) ^ mul3(b) ^ c ^ d;
    col[1] = a ^ mul2(b) ^ mul3(c) ^ d;
    col[2] = a ^ b ^ mul2(c) ^ mul3(d);
    col[3] = mul3(a) ^ b ^ c ^ mul2(d);
}

void inv_mix_single_column(uint8_t col[4])
{
    uint8_t a = col[0];
    uint8_t b = col[1];
    uint8_t c = col[2];
    uint8_t d = col[3];

    col[0] = mul14(a) ^ mul11(b) ^ mul13(c) ^ mul9(d);
    col[1] = mul9(a)  ^ mul14(b) ^ mul11(c) ^ mul13(d);
    col[2] = mul13(a) ^ mul9(b)  ^ mul14(c) ^ mul11(d);
    col[3] = mul11(a) ^ mul13(b) ^ mul9(c)  ^ mul14(d);
}

void mix_columns(uint8_t state[4][4])
{
    for(int j = 0; j < 4; j++) {
        uint8_t col[4] = {
            state[0][j],
            state[1][j],
            state[2][j],
            state[3][j]
        };

        mix_single_column(col);

        for(int i = 0; i < 4; i++) {
            state[i][j] = col[i];
        }
    }
}

void inv_mix_columns(uint8_t state[4][4])
{
    for(int j=0;j<4;j++)
    {
        uint8_t col[4] = {
            state[0][j],
            state[1][j],
            state[2][j],
            state[3][j]
        };

        inv_mix_single_column(col);

        for(int i=0;i<4;i++)
            state[i][j] = col[i];
    }
}

void rot_word(uint8_t word[4])
{
    uint8_t temp = word[0];

    word[0] = word[1];
    word[1] = word[2];
    word[2] = word[3];
    word[3] = temp;
}

void sub_word(uint8_t word[4])
{
    for(int i=0;i<4;i++)
        word[i] = sbox[word[i]];
}

static const uint8_t rcon[10] = {
    0x01,
    0x02,
    0x04,
    0x08,
    0x10,
    0x20,
    0x40,
    0x80,
    0x1B,
    0x36
};

void xor_words(uint8_t out[4],
               uint8_t a[4],
               uint8_t b[4])
{
    for(int i = 0; i < 4; i++) {
        out[i] = a[i] ^ b[i];
    }
}

void print_word(uint8_t w[4])
{
    for(int i=0;i<4;i++)
        printf("%02X ", w[i]);
    printf("\n");
}

void g(uint8_t word[4], int round)
{
    rot_word(word);
    sub_word(word);
    word[0] ^= rcon[round];
}

void key_expansion(uint8_t words[44][4])
{
    // Initial key (4 words)
    uint8_t w0[4] = {0x2B,0x7E,0x15,0x16};
    uint8_t w1[4] = {0x28,0xAE,0xD2,0xA6};
    uint8_t w2[4] = {0xAB,0xF7,0x15,0x88};
    uint8_t w3[4] = {0x09,0xCF,0x4F,0x3C};

    for(int j=0;j<4;j++) {
        words[0][j] = w0[j];
        words[1][j] = w1[j];
        words[2][j] = w2[j];
        words[3][j] = w3[j];
    }

    for(int i=4;i<44;i++) {
        uint8_t temp[4];
        for(int j=0;j<4;j++)
            temp[j] = words[i-1][j];

        if(i % 4 == 0) {
            g(temp, (i/4) - 1);
        }

        for(int j=0;j<4;j++) {
            words[i][j] = words[i-4][j] ^ temp[j];
        }
    }
}

void aes_round(uint8_t state[4][4],
               uint8_t round_key[4][4])
{
    sub_bytes(state);
    shift_rows(state);
    mix_columns(state);
    add_round_key(state, round_key);
}

void inv_aes_round(uint8_t state[4][4],
                   uint8_t round_key[4][4])
{
    add_round_key(state, round_key);
    inv_mix_columns(state);
    inv_shift_rows(state);
    inv_sub_bytes(state);
}

void final_round(uint8_t state[4][4],
                 uint8_t round_key[4][4])
{
    sub_bytes(state);
    shift_rows(state);
    add_round_key(state, round_key);
}

void build_round_key(uint8_t words[44][4],
                     int round,
                     uint8_t rk[4][4])
{
    int start = round * 4;

    for(int i=0;i<4;i++)
    {
        for(int j=0;j<4;j++)
        {
            rk[i][j] = words[start + i][j];
        }
    }
}

void aes128_encrypt(uint8_t state[4][4],
                    uint8_t words[44][4])
{
    uint8_t rk[4][4];

    // RoundKey0
    build_round_key(words, 0, rk);
    add_round_key(state, rk);

    // Rounds 1-9
    for(int round=1; round<=9; round++)
    {
        build_round_key(words, round, rk);
        aes_round(state, rk);
    }

    // Final round
    build_round_key(words, 10, rk);
    final_round(state, rk);
}

void aes128_decrypt(uint8_t state[4][4],
                    uint8_t words[44][4])
{
    uint8_t rk[4][4];

    // RoundKey10
    build_round_key(words, 10, rk);
    add_round_key(state, rk);

    inv_shift_rows(state);
    inv_sub_bytes(state);

    for(int round = 9; round >= 1; round--)
    {
        build_round_key(words, round, rk);

        add_round_key(state, rk);
        inv_mix_columns(state);
        inv_shift_rows(state);
        inv_sub_bytes(state);
    }

    build_round_key(words, 0, rk);
    add_round_key(state, rk);
}

int aes_test() {
    uint8_t state[4][4] = {
        {0x32,0x43,0xF6,0xA8},
        {0x88,0x5A,0x30,0x8D},
        {0x31,0x31,0x98,0xA2},
        {0xE0,0x37,0x07,0x34}
    };

    init_inv_sbox();

    uint8_t words[44][4];

    key_expansion(words);

    printf("Before AES:\n");
    print_state(state);

    aes128_encrypt(state, words);

    printf("\nAfter AES Encryption:\n");
    print_state(state);

    aes128_decrypt(state, words);

    printf("\nAfter AES Decryption:\n");
    print_state(state);

    return 0;
}