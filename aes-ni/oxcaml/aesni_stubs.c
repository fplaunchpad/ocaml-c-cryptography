/***********************************************************************/
/*  Based on the Cryptokit library by Xavier Leroy (INRIA).            */
/*  AES-NI-only variant for benchmarking — no software fallback.       */
/***********************************************************************/

/* Pull in the AES-NI implementation (copied to build dir via dune). */
#include "aesni.c"

#include <assert.h>
#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>

/* Cooked key layout:
     bytes 0..239  : expanded key schedule (15 round-key slots × 16 bytes)
     byte  240     : number of rounds (nr)                                */
#define Cooked_key_NR_offset  (15 * 16)
#define Cooked_key_size       (Cooked_key_NR_offset + 1)

/* cook_encrypt_key : bytes -> bytes
   Expands the raw key into an encryption key schedule. */
CAMLprim value caml_aes_cook_encrypt_key(value v_key)
{
    CAMLparam1(v_key);
    value ckey = caml_alloc_string(Cooked_key_size);

    if (aesni_available == -1) aesni_check_available();
    int nr = aesniKeySetupEnc(
        (unsigned char *)String_val(ckey),
        (const unsigned char *)String_val(v_key),
        (int)(8 * caml_string_length(v_key)));
    Byte(ckey, Cooked_key_NR_offset) = (char)nr;
    CAMLreturn(ckey);
}

/* cook_decrypt_key : bytes -> bytes */
CAMLprim value caml_aes_cook_decrypt_key(value v_key)
{
    CAMLparam1(v_key);
    value ckey = caml_alloc_string(Cooked_key_size);

    if (aesni_available == -1) aesni_check_available();
    int nr = aesniKeySetupDec(
        (unsigned char *)String_val(ckey),
        (const unsigned char *)String_val(v_key),
        (int)(8 * caml_string_length(v_key)));
    Byte(ckey, Cooked_key_NR_offset) = (char)nr;
    CAMLreturn(ckey);
}

/* encrypt_block : ckey -> src -> src_off -> dst -> dst_off -> unit
   Encrypts one 16-byte block. No CAMLparam needed — no GC allocation. */
CAMLprim value caml_aes_encrypt(value v_ckey, value v_src, value v_src_ofs,
                                value v_dst,  value v_dst_ofs)
{
    aesniEncrypt(
        (const unsigned char *)String_val(v_ckey),
        (unsigned char)Byte(v_ckey, Cooked_key_NR_offset),
        (const unsigned char *)&Byte(v_src, Long_val(v_src_ofs)),
        (unsigned char *)&Byte(v_dst, Long_val(v_dst_ofs)));
    return Val_unit;
}

/* decrypt_block : ckey -> src -> src_off -> dst -> dst_off -> unit */
CAMLprim value caml_aes_decrypt(value v_ckey, value v_src, value v_src_ofs,
                                value v_dst,  value v_dst_ofs)
{
    aesniDecrypt(
        (const unsigned char *)String_val(v_ckey),
        (unsigned char)Byte(v_ckey, Cooked_key_NR_offset),
        (const unsigned char *)&Byte(v_src, Long_val(v_src_ofs)),
        (unsigned char *)&Byte(v_dst, Long_val(v_dst_ofs)));
    return Val_unit;
}

/* check_available : unit -> int  (1 = AES-NI present) */
CAMLprim value caml_aesni_check(value v_unit)
{
    (void)v_unit;
    return Val_int(aesni_check_available());
}

/* ---- Raw AES-NI instructions for OxCaml SIMD ----------------------------
   OxCaml passes/returns (int64x2[@unboxed]) in XMM registers (System V AMD64 ABI).
   __m128i matches that convention exactly. Never allocate, never touch GC. */

__m128i caml_aesni_aesenc(__m128i state, __m128i key) {
    return _mm_aesenc_si128(state, key);
}
__m128i caml_aesni_aesenclast(__m128i state, __m128i key) {
    return _mm_aesenclast_si128(state, key);
}
__m128i caml_aesni_aesdec(__m128i state, __m128i key) {
    return _mm_aesdec_si128(state, key);
}
__m128i caml_aesni_aesdeclast(__m128i state, __m128i key) {
    return _mm_aesdeclast_si128(state, key);
}
__m128i caml_aesni_aesimc(__m128i key) {
    return _mm_aesimc_si128(key);
}

/* imm8 must be compile-time constant in C — enumerate all rcon values
   used by AES-128 / 192 / 256 key expansion. */
__m128i caml_aesni_keygenassist(intnat imm8, __m128i key) {
    switch ((unsigned char)imm8) {
    case 0x00: return _mm_aeskeygenassist_si128(key, 0x00);
    case 0x01: return _mm_aeskeygenassist_si128(key, 0x01);
    case 0x02: return _mm_aeskeygenassist_si128(key, 0x02);
    case 0x04: return _mm_aeskeygenassist_si128(key, 0x04);
    case 0x08: return _mm_aeskeygenassist_si128(key, 0x08);
    case 0x10: return _mm_aeskeygenassist_si128(key, 0x10);
    case 0x1b: return _mm_aeskeygenassist_si128(key, 0x1b);
    case 0x20: return _mm_aeskeygenassist_si128(key, 0x20);
    case 0x36: return _mm_aeskeygenassist_si128(key, 0x36);
    case 0x40: return _mm_aeskeygenassist_si128(key, 0x40);
    case 0x55: return _mm_aeskeygenassist_si128(key, 0x55);
    case 0x80: return _mm_aeskeygenassist_si128(key, 0x80);
    default:   __builtin_unreachable();
    }
}

/* ---- Stub symbols for OxCaml [@@builtin] ops ----------------------------
   Compiler inlines these as SIMD instructions; linker still needs the symbol. */
#define BUILTIN(name) void name() { assert(0); }
BUILTIN(caml_vec128_unreachable)
BUILTIN(caml_sse_vec128_xor)
BUILTIN(caml_sse_vec128_shuffle_32)
BUILTIN(caml_sse2_vec128_shift_left_bytes)
BUILTIN(caml_sse2_vec128_shuffle_64)
