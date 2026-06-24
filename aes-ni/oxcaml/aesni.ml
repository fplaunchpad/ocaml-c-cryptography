(** AES-NI via OxCaml SIMD.
    - XOR, shuffle, shift, load/store: OxCaml SIMD builtins (inlined, zero overhead)
    - aesenc/aesdec/aesimc/keygenassist: C stubs (AES-NI hw, not yet in OxCaml builtins) *)

(* ---- OxCaml SIMD builtins ------------------------------------------------
   [@@builtin] = compiler inlines as a single SIMD instruction, no function call. *)

external xor128 : (int64x2[@unboxed]) -> (int64x2[@unboxed]) -> (int64x2[@unboxed])
  = "caml_vec128_unreachable" "caml_sse_vec128_xor"
  [@@noalloc] [@@builtin]

(* shuffle32 imm a b = SHUFPS(a,b,imm):
   result[31:0]   = a[imm[1:0]]
   result[63:32]  = a[imm[3:2]]
   result[95:64]  = b[imm[5:4]]
   result[127:96] = b[imm[7:6]]
   For a self-shuffle (PSHUFD equivalent) pass the same register for both a and b. *)
external shuffle32 : (int[@untagged]) -> (int64x2[@unboxed]) -> (int64x2[@unboxed]) -> (int64x2[@unboxed])
  = "caml_vec128_unreachable" "caml_sse_vec128_shuffle_32"
  [@@noalloc] [@@builtin]

external shift_left_bytes : (int[@untagged]) -> (int64x2[@unboxed]) -> (int64x2[@unboxed])
  = "caml_vec128_unreachable" "caml_sse2_vec128_shift_left_bytes"
  [@@noalloc] [@@builtin]

(* shuffle_64 imm a b = SHUFPD(a,b,imm):
   result[63:0]   = imm[0]=0 ? a_low  : a_high
   result[127:64] = imm[1]=0 ? b_low  : b_high *)
external shuffle64 : (int[@untagged]) -> (int64x2[@unboxed]) -> (int64x2[@unboxed]) -> (int64x2[@unboxed])
  = "caml_vec128_unreachable" "caml_sse2_vec128_shuffle_64"
  [@@noalloc] [@@builtin]

(* Load/store 128-bit from bytes at byte offset — compiler primitive, no boxing *)
external get128 : bytes -> int -> int64x2 = "%caml_bytes_getu128u"
external set128 : bytes -> int -> int64x2 -> unit = "%caml_bytes_setu128u"

(* ---- AES-NI hardware instructions (C stubs) ------------------------------ *)

external aesenc : (int64x2[@unboxed]) -> (int64x2[@unboxed]) -> (int64x2[@unboxed])
  = "caml_vec128_unreachable" "caml_aesni_aesenc" [@@noalloc]

external aesenclast : (int64x2[@unboxed]) -> (int64x2[@unboxed]) -> (int64x2[@unboxed])
  = "caml_vec128_unreachable" "caml_aesni_aesenclast" [@@noalloc]

external aesdec : (int64x2[@unboxed]) -> (int64x2[@unboxed]) -> (int64x2[@unboxed])
  = "caml_vec128_unreachable" "caml_aesni_aesdec" [@@noalloc]

external aesdeclast : (int64x2[@unboxed]) -> (int64x2[@unboxed]) -> (int64x2[@unboxed])
  = "caml_vec128_unreachable" "caml_aesni_aesdeclast" [@@noalloc]

external aesimc : (int64x2[@unboxed]) -> (int64x2[@unboxed])
  = "caml_vec128_unreachable" "caml_aesni_aesimc" [@@noalloc]

external keygenassist : (int[@untagged]) -> (int64x2[@unboxed]) -> (int64x2[@unboxed])
  = "caml_vec128_unreachable" "caml_aesni_keygenassist" [@@noalloc]

(* ---- Key layout ----------------------------------------------------------
   15 slots × 16 bytes = 240 bytes for round keys, 1 byte for nr at the end *)
let cooked_key_size      = 15 * 16 + 1
let cooked_key_nr_offset = 15 * 16

external check_available : unit -> int = "caml_aesni_check"

(* ---- Key expansion helpers (pure OxCaml SIMD) ----------------------------
   These match the C aesni_128_assist / 192_assist / 256_assist_1 / _2 exactly. *)

(* AES-128 and AES-256 assist-1: cascade XOR then merge with shuffled t2 *)
let[@inline] assist128 t1 t2 =
  let t2 = shuffle32 0xff t2 t2 in
  let t3 = shift_left_bytes 4 t1 in
  let t1 = xor128 t1 t3 in
  let t3 = shift_left_bytes 4 t3 in
  let t1 = xor128 t1 t3 in
  let t3 = shift_left_bytes 4 t3 in
  let t1 = xor128 t1 t3 in
  xor128 t1 t2

(* AES-192 assist: updates both t1 and t3, returns (t1, t3) *)
let[@inline] assist192 t1 t2 t3 =
  let t2 = shuffle32 0x55 t2 t2 in
  let t4 = shift_left_bytes 4 t1 in
  let t1 = xor128 t1 t4 in
  let t4 = shift_left_bytes 4 t4 in
  let t1 = xor128 t1 t4 in
  let t4 = shift_left_bytes 4 t4 in
  let t1 = xor128 t1 t4 in
  let t1 = xor128 t1 t2 in
  let t2 = shuffle32 0xff t1 t1 in
  let t4 = shift_left_bytes 4 t3 in
  let t3 = xor128 t3 t4 in
  let t3 = xor128 t3 t2 in
  (t1, t3)

(* AES-256 assist-2: uses keygenassist 0x00 on t1 to derive next t3 *)
let[@inline] assist256_2 t1 t3 =
  let t4 = keygenassist 0x00 t1 in
  let t2 = shuffle32 0xaa t4 t4 in
  let t4 = shift_left_bytes 4 t3 in
  let t3 = xor128 t3 t4 in
  let t4 = shift_left_bytes 4 t4 in
  let t3 = xor128 t3 t4 in
  let t4 = shift_left_bytes 4 t4 in
  let t3 = xor128 t3 t4 in
  xor128 t3 t2

(* ---- AES-128 key expansion (11 round keys, nr=10) ----------------------- *)
let expand128 key ckey =
  let t1 = get128 key 0 in
  set128 ckey   0 t1;
  let t1 = assist128 t1 (keygenassist 0x01 t1) in set128 ckey  16 t1;
  let t1 = assist128 t1 (keygenassist 0x02 t1) in set128 ckey  32 t1;
  let t1 = assist128 t1 (keygenassist 0x04 t1) in set128 ckey  48 t1;
  let t1 = assist128 t1 (keygenassist 0x08 t1) in set128 ckey  64 t1;
  let t1 = assist128 t1 (keygenassist 0x10 t1) in set128 ckey  80 t1;
  let t1 = assist128 t1 (keygenassist 0x20 t1) in set128 ckey  96 t1;
  let t1 = assist128 t1 (keygenassist 0x40 t1) in set128 ckey 112 t1;
  let t1 = assist128 t1 (keygenassist 0x80 t1) in set128 ckey 128 t1;
  let t1 = assist128 t1 (keygenassist 0x1b t1) in set128 ckey 144 t1;
  let t1 = assist128 t1 (keygenassist 0x36 t1) in set128 ckey 160 t1;
  10

(* ---- AES-192 key expansion (13 round keys, nr=12) -----------------------
   192-bit keys pack into 128-bit slots with shuffle_pd interleaving. *)
let expand192 key ckey =
  let t1 = get128 key 0 in
  let t3 = get128 key 16 in
  set128 ckey 0 t1;
  (* Round 1 *)
  let t3s = t3 in
  let (t1, t3) = assist192 t1 (keygenassist 0x01 t3) t3 in
  set128 ckey  16 (shuffle64 0 t3s t1);   (* {t3s_low,  t1_low}  *)
  set128 ckey  32 (shuffle64 1 t1  t3);   (* {t1_high,  t3_low}  *)
  (* Round 2 *)
  let (t1, t3) = assist192 t1 (keygenassist 0x02 t3) t3 in
  set128 ckey  48 t1;
  (* Round 3 *)
  let t3s = t3 in
  let (t1, t3) = assist192 t1 (keygenassist 0x04 t3) t3 in
  set128 ckey  64 (shuffle64 0 t3s t1);
  set128 ckey  80 (shuffle64 1 t1  t3);
  (* Round 4 *)
  let (t1, t3) = assist192 t1 (keygenassist 0x08 t3) t3 in
  set128 ckey  96 t1;
  (* Round 5 *)
  let t3s = t3 in
  let (t1, t3) = assist192 t1 (keygenassist 0x10 t3) t3 in
  set128 ckey 112 (shuffle64 0 t3s t1);
  set128 ckey 128 (shuffle64 1 t1  t3);
  (* Round 6 *)
  let (t1, t3) = assist192 t1 (keygenassist 0x20 t3) t3 in
  set128 ckey 144 t1;
  (* Round 7 *)
  let t3s = t3 in
  let (t1, t3) = assist192 t1 (keygenassist 0x40 t3) t3 in
  set128 ckey 160 (shuffle64 0 t3s t1);
  set128 ckey 176 (shuffle64 1 t1  t3);
  (* Round 8 *)
  let (t1, _)  = assist192 t1 (keygenassist 0x80 t3) t3 in
  set128 ckey 192 t1;
  12

(* ---- AES-256 key expansion (15 round keys, nr=14) ----------------------- *)
let expand256 key ckey =
  let t1 = get128 key 0 in
  let t3 = get128 key 16 in
  set128 ckey   0 t1;
  set128 ckey  16 t3;
  let t1 = assist128   t1 (keygenassist 0x01 t3) in set128 ckey  32 t1;
  let t3 = assist256_2 t1 t3                     in set128 ckey  48 t3;
  let t1 = assist128   t1 (keygenassist 0x02 t3) in set128 ckey  64 t1;
  let t3 = assist256_2 t1 t3                     in set128 ckey  80 t3;
  let t1 = assist128   t1 (keygenassist 0x04 t3) in set128 ckey  96 t1;
  let t3 = assist256_2 t1 t3                     in set128 ckey 112 t3;
  let t1 = assist128   t1 (keygenassist 0x08 t3) in set128 ckey 128 t1;
  let t3 = assist256_2 t1 t3                     in set128 ckey 144 t3;
  let t1 = assist128   t1 (keygenassist 0x10 t3) in set128 ckey 160 t1;
  let t3 = assist256_2 t1 t3                     in set128 ckey 176 t3;
  let t1 = assist128   t1 (keygenassist 0x20 t3) in set128 ckey 192 t1;
  let t3 = assist256_2 t1 t3                     in set128 ckey 208 t3;
  let t1 = assist128   t1 (keygenassist 0x40 t3) in set128 ckey 224 t1;
  14

(* ---- Public key setup ---------------------------------------------------- *)

let cook_encrypt_key key =
  let ckey = Bytes.create cooked_key_size in
  let nr = match Bytes.length key with
    | 16 -> expand128 key ckey
    | 24 -> expand192 key ckey
    | 32 -> expand256 key ckey
    | _  -> invalid_arg "cook_encrypt_key: key must be 16, 24, or 32 bytes"
  in
  Bytes.set ckey cooked_key_nr_offset (Char.chr nr);
  ckey

let cook_decrypt_key key =
  let ckey_enc = cook_encrypt_key key in
  let nr = Char.code (Bytes.get ckey_enc cooked_key_nr_offset) in
  let ckey = Bytes.create cooked_key_size in
  set128 ckey 0 (get128 ckey_enc (nr * 16));
  for i = 1 to nr - 1 do
    set128 ckey (i * 16) (aesimc (get128 ckey_enc ((nr - i) * 16)))
  done;
  set128 ckey (nr * 16) (get128 ckey_enc 0);
  Bytes.set ckey cooked_key_nr_offset (Char.chr nr);
  ckey

(* ---- Encrypt one 16-byte block (fully unrolled per key size) -------------
   Keeping t in a let-chain lets Flambda2 keep it in an XMM register
   throughout without heap allocation. *)

let[@inline] encrypt128 ckey src soff dst doff =
  let t = get128 src soff in
  let t = xor128      t (get128 ckey   0) in
  let t = aesenc      t (get128 ckey  16) in
  let t = aesenc      t (get128 ckey  32) in
  let t = aesenc      t (get128 ckey  48) in
  let t = aesenc      t (get128 ckey  64) in
  let t = aesenc      t (get128 ckey  80) in
  let t = aesenc      t (get128 ckey  96) in
  let t = aesenc      t (get128 ckey 112) in
  let t = aesenc      t (get128 ckey 128) in
  let t = aesenc      t (get128 ckey 144) in
  let t = aesenclast  t (get128 ckey 160) in
  set128 dst doff t

let[@inline] encrypt192 ckey src soff dst doff =
  let t = get128 src soff in
  let t = xor128      t (get128 ckey   0) in
  let t = aesenc      t (get128 ckey  16) in
  let t = aesenc      t (get128 ckey  32) in
  let t = aesenc      t (get128 ckey  48) in
  let t = aesenc      t (get128 ckey  64) in
  let t = aesenc      t (get128 ckey  80) in
  let t = aesenc      t (get128 ckey  96) in
  let t = aesenc      t (get128 ckey 112) in
  let t = aesenc      t (get128 ckey 128) in
  let t = aesenc      t (get128 ckey 144) in
  let t = aesenc      t (get128 ckey 160) in
  let t = aesenc      t (get128 ckey 176) in
  let t = aesenclast  t (get128 ckey 192) in
  set128 dst doff t

let[@inline] encrypt256 ckey src soff dst doff =
  let t = get128 src soff in
  let t = xor128      t (get128 ckey   0) in
  let t = aesenc      t (get128 ckey  16) in
  let t = aesenc      t (get128 ckey  32) in
  let t = aesenc      t (get128 ckey  48) in
  let t = aesenc      t (get128 ckey  64) in
  let t = aesenc      t (get128 ckey  80) in
  let t = aesenc      t (get128 ckey  96) in
  let t = aesenc      t (get128 ckey 112) in
  let t = aesenc      t (get128 ckey 128) in
  let t = aesenc      t (get128 ckey 144) in
  let t = aesenc      t (get128 ckey 160) in
  let t = aesenc      t (get128 ckey 176) in
  let t = aesenc      t (get128 ckey 192) in
  let t = aesenc      t (get128 ckey 208) in
  let t = aesenclast  t (get128 ckey 224) in
  set128 dst doff t

let encrypt_block ckey src soff dst doff =
  match Char.code (Bytes.unsafe_get ckey cooked_key_nr_offset) with
  | 10 -> encrypt128 ckey src soff dst doff
  | 12 -> encrypt192 ckey src soff dst doff
  | 14 -> encrypt256 ckey src soff dst doff
  | _  -> assert false

(* ---- Decrypt one 16-byte block (fully unrolled per key size) ------------- *)

let[@inline] decrypt128 ckey src soff dst doff =
  let t = get128 src soff in
  let t = xor128      t (get128 ckey   0) in
  let t = aesdec      t (get128 ckey  16) in
  let t = aesdec      t (get128 ckey  32) in
  let t = aesdec      t (get128 ckey  48) in
  let t = aesdec      t (get128 ckey  64) in
  let t = aesdec      t (get128 ckey  80) in
  let t = aesdec      t (get128 ckey  96) in
  let t = aesdec      t (get128 ckey 112) in
  let t = aesdec      t (get128 ckey 128) in
  let t = aesdec      t (get128 ckey 144) in
  let t = aesdeclast  t (get128 ckey 160) in
  set128 dst doff t

let[@inline] decrypt192 ckey src soff dst doff =
  let t = get128 src soff in
  let t = xor128      t (get128 ckey   0) in
  let t = aesdec      t (get128 ckey  16) in
  let t = aesdec      t (get128 ckey  32) in
  let t = aesdec      t (get128 ckey  48) in
  let t = aesdec      t (get128 ckey  64) in
  let t = aesdec      t (get128 ckey  80) in
  let t = aesdec      t (get128 ckey  96) in
  let t = aesdec      t (get128 ckey 112) in
  let t = aesdec      t (get128 ckey 128) in
  let t = aesdec      t (get128 ckey 144) in
  let t = aesdec      t (get128 ckey 160) in
  let t = aesdec      t (get128 ckey 176) in
  let t = aesdeclast  t (get128 ckey 192) in
  set128 dst doff t

let[@inline] decrypt256 ckey src soff dst doff =
  let t = get128 src soff in
  let t = xor128      t (get128 ckey   0) in
  let t = aesdec      t (get128 ckey  16) in
  let t = aesdec      t (get128 ckey  32) in
  let t = aesdec      t (get128 ckey  48) in
  let t = aesdec      t (get128 ckey  64) in
  let t = aesdec      t (get128 ckey  80) in
  let t = aesdec      t (get128 ckey  96) in
  let t = aesdec      t (get128 ckey 112) in
  let t = aesdec      t (get128 ckey 128) in
  let t = aesdec      t (get128 ckey 144) in
  let t = aesdec      t (get128 ckey 160) in
  let t = aesdec      t (get128 ckey 176) in
  let t = aesdec      t (get128 ckey 192) in
  let t = aesdec      t (get128 ckey 208) in
  let t = aesdeclast  t (get128 ckey 224) in
  set128 dst doff t

let decrypt_block ckey src soff dst doff =
  match Char.code (Bytes.unsafe_get ckey cooked_key_nr_offset) with
  | 10 -> decrypt128 ckey src soff dst doff
  | 12 -> decrypt192 ckey src soff dst doff
  | 14 -> decrypt256 ckey src soff dst doff
  | _  -> assert false
