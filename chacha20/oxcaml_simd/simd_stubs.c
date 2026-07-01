/* These symbols appear in the primitive table that asmgen emits for
   [@@builtin] externals, but are never reached at runtime — the native
   compiler replaces every call site with an inline SSE instruction.
   Defined here only to satisfy the linker. */
#define BUILTIN(name) void name(void) { __builtin_unreachable(); }

BUILTIN(caml_sse2_int32x4_add)
BUILTIN(caml_sse_vec128_xor)
BUILTIN(caml_sse2_int32x4_slli)
BUILTIN(caml_sse2_int32x4_srli)
BUILTIN(caml_ssse3_vec128_shuffle_8)
BUILTIN(caml_sse_vec128_shuffle_32)
