#pragma once
#include <stddef.h>
#include <stdint.h>

typedef struct {
    uint32_t input[16];  /* current state words (little-endian on x86) */
    uint8_t  output[64]; /* current keystream block                     */
    int      next;       /* next unused byte index in output            */
    size_t   iv_length;  /* 8 (64-bit nonce) or 12 (96-bit nonce/IETF) */
} chacha20_simd_ctx;

void chacha20_init     (chacha20_simd_ctx *ctx,
                        const uint8_t *key, size_t key_length,
                        const uint8_t *iv,  size_t iv_length,
                        uint64_t counter);

void chacha20_transform(chacha20_simd_ctx *ctx,
                        const uint8_t *in, uint8_t *out, size_t len);

void chacha20_extract  (chacha20_simd_ctx *ctx,
                        uint8_t *out, size_t len);
