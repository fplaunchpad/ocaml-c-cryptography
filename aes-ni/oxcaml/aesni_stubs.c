/***********************************************************************/
/*  Based on the Cryptokit library by Xavier Leroy (INRIA).            */
/*  AES-NI-only variant for benchmarking — no software fallback.       */
/***********************************************************************/

/* Pull in the AES-NI implementation (copied to build dir via dune). */
#include "aesni.c"

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
