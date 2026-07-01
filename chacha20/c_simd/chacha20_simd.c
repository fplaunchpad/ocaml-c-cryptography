/*
 * ChaCha20 — hand-written SSE2/SSSE3 implementation.
 *
 * Strategy: mirrors the OxCaml SIMD implementation exactly.
 * State rows a/b/c/d are __m128i vectors (4 × uint32 lanes).
 * Every intrinsic maps 1-to-1 to an OxCaml [@@builtin] external.
 *
 * Requires: SSE2 (baseline x86-64) + SSSE3 (for PSHUFB / _mm_shuffle_epi8).
 * Compile:  -O3 -march=native  (implies both on any modern x86 CPU).
 */

#include "chacha20_simd.h"

#include <assert.h>
#include <string.h>
#include <immintrin.h>   /* SSE2  */
#include <tmmintrin.h>   /* SSSE3 — _mm_shuffle_epi8 */

/* =========================================================================
 * Section 1: intrinsic wrappers
 * Each macro name matches the OxCaml builtin it mirrors.
 * ========================================================================= */

/* PADDD — packed 32-bit add mod 2^32  (caml_sse2_int32x4_add) */
#define VEC_ADD(a, b)     _mm_add_epi32((a), (b))

/* XORPS — 128-bit bitwise XOR         (caml_sse_vec128_xor)   */
#define VEC_XOR(a, b)     _mm_xor_si128((a), (b))

/* PSLLD — shift each 32-bit lane left  (caml_sse2_int32x4_slli) */
#define VEC_SLLI(n, v)    _mm_slli_epi32((v), (n))

/* PSRLD — shift each 32-bit lane right (caml_sse2_int32x4_srli) */
#define VEC_SRLI(n, v)    _mm_srli_epi32((v), (n))

/* PSHUFB — byte-permute via 16-byte mask (caml_ssse3_vec128_shuffle_8) */
#define PSHUFB(v, mask)   _mm_shuffle_epi8((v), (mask))

/* PSHUFD — 32-bit word shuffle with imm8 (caml_sse_vec128_shuffle_32,
   used with src1=src2 which makes SHUFPS behave as PSHUFD)             */
#define PSHUFD(imm, v)    _mm_shuffle_epi32((v), (imm))


/* =========================================================================
 * Section 2: bit-rotations within each 32-bit lane
 *
 * rot16: swap 16-bit halves  — PSHUFB, same mask as OxCaml rot16_mask_bytes
 *   word bytes [b0,b1,b2,b3] → [b2,b3,b0,b1]
 *   PSHUFB source indices (byte 0..15): 2,3,0,1, 6,7,4,5, 10,11,8,9, 14,15,12,13
 *
 * rot8:  cyclic left by 8    — PSHUFB, same mask as OxCaml rot8_mask_bytes
 *   word bytes [b0,b1,b2,b3] → [b3,b0,b1,b2]
 *   PSHUFB source indices: 3,0,1,2, 7,4,5,6, 11,8,9,10, 15,12,13,14
 *
 * rot12: shift-XOR pair      — mirrors OxCaml rotate_left_12
 * rot7:  shift-XOR pair      — mirrors OxCaml rotate_left_7
 * ========================================================================= */

/* _mm_set_epi8 args go HIGH byte → LOW byte (b15..b0) */
static const uint8_t rot16_mask_data[16] = {
    0x02, 0x03, 0x00, 0x01,
    0x06, 0x07, 0x04, 0x05,
    0x0a, 0x0b, 0x08, 0x09,
    0x0e, 0x0f, 0x0c, 0x0d
};

static const uint8_t rot8_mask_data[16] = {
    0x03, 0x00, 0x01, 0x02,
    0x07, 0x04, 0x05, 0x06,
    0x0b, 0x08, 0x09, 0x0a,
    0x0f, 0x0c, 0x0d, 0x0e
};

#define ROTL16(v, r16)    PSHUFB((v), (r16))
#define ROTL12(v)         VEC_XOR(VEC_SLLI(12, (v)), VEC_SRLI(20, (v)))
#define ROTL8(v, r8)      PSHUFB((v), (r8))
#define ROTL7(v)          VEC_XOR(VEC_SLLI(7,  (v)), VEC_SRLI(25, (v)))


/* =========================================================================
 * Section 3: word-lane rotations within __m128i (PSHUFD)
 *
 * imm8 encoding: bits[1:0]→dest[0], [3:2]→dest[1], [5:4]→dest[2], [7:6]→dest[3]
 *   rot_w1: [w0,w1,w2,w3] → [w1,w2,w3,w0]   imm8 = 0x39 = 00_11_10_01
 *   rot_w2: [w0,w1,w2,w3] → [w2,w3,w0,w1]   imm8 = 0x4E = 01_00_11_10
 *   rot_w3: [w0,w1,w2,w3] → [w3,w0,w1,w2]   imm8 = 0x93 = 10_01_00_11
 * Identical imm8 values as OxCaml rot_w1/rot_w2/rot_w3.
 * ========================================================================= */

#define ROT_W1(v)   PSHUFD(0x39, (v))
#define ROT_W2(v)   PSHUFD(0x4E, (v))
#define ROT_W3(v)   PSHUFD(0x93, (v))


/* =========================================================================
 * Section 4: quarter-round
 *
 * a,b,c,d are __m128i rows — one macro call executes 4 independent ChaCha20
 * quarter-rounds simultaneously, one per SIMD lane.
 * Mirrors OxCaml `quarterround` exactly, operation by operation.
 * ========================================================================= */

#define QUARTERROUND(a, b, c, d, r16, r8) \
    (a) = VEC_ADD((a), (b));              \
    (d) = VEC_XOR((d), (a));              \
    (d) = ROTL16((d), (r16));             \
    (c) = VEC_ADD((c), (d));              \
    (b) = VEC_XOR((b), (c));              \
    (b) = ROTL12((b));                    \
    (a) = VEC_ADD((a), (b));              \
    (d) = VEC_XOR((d), (a));              \
    (d) = ROTL8((d), (r8));               \
    (c) = VEC_ADD((c), (d));              \
    (b) = VEC_XOR((b), (c));              \
    (b) = ROTL7((b));


/* =========================================================================
 * Section 5: double-round (column round + diagonal round)
 *
 * Column round:   QUARTERROUND(a,b,c,d) — all 4 columns in parallel.
 * Diagonal round: rotate b/c/d with PSHUFD to bring diagonals into column
 *                 positions, run QUARTERROUND, then undo the rotations.
 *
 *   b  →rot_w1→  [s5, s6, s7, s4]    undo: rot_w3
 *   c  →rot_w2→  [s10,s11,s8, s9]    undo: rot_w2  (self-inverse)
 *   d  →rot_w3→  [s15,s12,s13,s14]   undo: rot_w1
 *
 * Mirrors OxCaml `double_round` exactly.
 * ========================================================================= */

#define DOUBLE_ROUND(a, b, c, d, r16, r8) \
    QUARTERROUND((a), (b), (c), (d), (r16), (r8)) \
    (b) = ROT_W1((b));                             \
    (c) = ROT_W2((c));                             \
    (d) = ROT_W3((d));                             \
    QUARTERROUND((a), (b), (c), (d), (r16), (r8)) \
    (b) = ROT_W3((b));                             \
    (c) = ROT_W2((c));                             \
    (d) = ROT_W1((d));


/* =========================================================================
 * Section 6: ChaCha20 block function
 *
 * Loads state rows into SIMD registers, runs 10 double-rounds (= 20 rounds),
 * adds the initial state, stores 64-byte keystream output.
 * ========================================================================= */

static void chacha20_block(chacha20_simd_ctx *ctx)
{
    const __m128i r16 = _mm_loadu_si128((const __m128i *)rot16_mask_data);
    const __m128i r8  = _mm_loadu_si128((const __m128i *)rot8_mask_data);

    /* Load four state rows — mirrors OxCaml `load constant_bytes 0` etc. */
    __m128i a = _mm_loadu_si128((const __m128i *)&ctx->input[0]);
    __m128i b = _mm_loadu_si128((const __m128i *)&ctx->input[4]);
    __m128i c = _mm_loadu_si128((const __m128i *)&ctx->input[8]);
    __m128i d = _mm_loadu_si128((const __m128i *)&ctx->input[12]);

    /* Save initial state for the final addition */
    const __m128i a0 = a, b0 = b, c0 = c, d0 = d;

    /* 10 double-rounds = 20 rounds total */
    int i;
    for (i = 0; i < 10; i++) {
        DOUBLE_ROUND(a, b, c, d, r16, r8)
    }

    /* Add initial state back — mirrors OxCaml `vec_add a s0` etc. */
    a = VEC_ADD(a, a0);
    b = VEC_ADD(b, b0);
    c = VEC_ADD(c, c0);
    d = VEC_ADD(d, d0);

    /* Store 64-byte keystream block */
    _mm_storeu_si128((__m128i *)&ctx->output[0],  a);
    _mm_storeu_si128((__m128i *)&ctx->output[16], b);
    _mm_storeu_si128((__m128i *)&ctx->output[32], c);
    _mm_storeu_si128((__m128i *)&ctx->output[48], d);

    /* Increment 32-bit (IETF) or 64-bit counter */
    if (++ctx->input[12] == 0 && ctx->iv_length == 8)
        ctx->input[13]++;
}


/* =========================================================================
 * Section 7: public API — identical logic to scalar, only block() differs
 * ========================================================================= */

static inline uint32_t load_le32(const uint8_t *p)
{
    uint32_t v;
    memcpy(&v, p, 4);  /* correct on little-endian x86; avoids UB */
    return v;
}

void chacha20_init(chacha20_simd_ctx *ctx,
                   const uint8_t *key, size_t key_length,
                   const uint8_t *iv,  size_t iv_length,
                   uint64_t counter)
{
    static const uint8_t constants32[16] = "expand 32-byte k";
    static const uint8_t constants16[16] = "expand 16-byte k";
    const uint8_t *constants = (key_length == 32) ? constants32 : constants16;

    assert(key_length == 16 || key_length == 32);
    assert(iv_length  == 8  || iv_length  == 12);

    ctx->input[0]  = load_le32(constants + 0);
    ctx->input[1]  = load_le32(constants + 4);
    ctx->input[2]  = load_le32(constants + 8);
    ctx->input[3]  = load_le32(constants + 12);

    ctx->input[4]  = load_le32(key + 0);
    ctx->input[5]  = load_le32(key + 4);
    ctx->input[6]  = load_le32(key + 8);
    ctx->input[7]  = load_le32(key + 12);

    if (key_length == 32) key += 16;
    ctx->input[8]  = load_le32(key + 0);
    ctx->input[9]  = load_le32(key + 4);
    ctx->input[10] = load_le32(key + 8);
    ctx->input[11] = load_le32(key + 12);

    ctx->input[12] = (uint32_t)counter;
    if (iv_length == 8) {
        ctx->input[13] = (uint32_t)(counter >> 32);
        ctx->input[14] = load_le32(iv + 0);
        ctx->input[15] = load_le32(iv + 4);
    } else {
        ctx->input[13] = load_le32(iv + 0);
        ctx->input[14] = load_le32(iv + 4);
        ctx->input[15] = load_le32(iv + 8);
    }

    ctx->iv_length = iv_length;
    ctx->next      = 64;  /* force block generation on first use */
}

void chacha20_transform(chacha20_simd_ctx *ctx,
                        const uint8_t *in, uint8_t *out, size_t len)
{
    int n = ctx->next;
    for (; len > 0; len--) {
        if (n >= 64) { chacha20_block(ctx); n = 0; }
        *out++ = *in++ ^ ctx->output[n++];
    }
    ctx->next = n;
}

void chacha20_extract(chacha20_simd_ctx *ctx, uint8_t *out, size_t len)
{
    int n = ctx->next;
    for (; len > 0; len--) {
        if (n >= 64) { chacha20_block(ctx); n = 0; }
        *out++ = ctx->output[n++];
    }
    ctx->next = n;
}
