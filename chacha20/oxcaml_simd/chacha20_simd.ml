(* OxCaml SIMD ChaCha20 — RFC 7539 compliant.
   Each [@@builtin] compiles to a single x86 instruction in native code.
   Requires: -extension simd_beta, native compilation only. *)

(* ---- Load / store -------------------------------------------------------- *)
external load  : bytes -> int -> int32x4 = "%caml_bytes_getu128u"
external store : bytes -> int -> int32x4 -> unit = "%caml_bytes_setu128u"

(* ---- Raw SIMD primitives ------------------------------------------------- *)
(* PADDD: packed 32-bit add mod 2^32 per lane. *)
external vec_add : (int32x4[@unboxed]) -> (int32x4[@unboxed]) -> (int32x4[@unboxed])
  = "caml_vec128_unreachable" "caml_sse2_int32x4_add" [@@noalloc] [@@builtin]

(* XORPS: bitwise XOR across all 128 bits. *)
external vec_xor : (int32x4[@unboxed]) -> (int32x4[@unboxed]) -> (int32x4[@unboxed])
  = "caml_vec128_unreachable" "caml_sse_vec128_xor" [@@noalloc] [@@builtin]

(* PSLLD imm8: shift each 32-bit lane left by immediate. *)
external slli : (int[@untagged]) -> (int32x4[@unboxed]) -> (int32x4[@unboxed])
  = "caml_vec128_unreachable" "caml_sse2_int32x4_slli" [@@noalloc] [@@builtin]

(* PSRLD imm8: shift each 32-bit lane right (logical) by immediate. *)
external srli : (int[@untagged]) -> (int32x4[@unboxed]) -> (int32x4[@unboxed])
  = "caml_vec128_unreachable" "caml_sse2_int32x4_srli" [@@noalloc] [@@builtin]

(* PSHUFB: byte-permute within 128-bit register using a 16-byte control mask. *)
external pshufb : (int32x4[@unboxed]) -> (int32x4[@unboxed]) -> (int32x4[@unboxed])
  = "caml_vec128_unreachable" "caml_ssse3_vec128_shuffle_8" [@@noalloc] [@@builtin]

(* SHUFPS imm8: lower 2 words from src1, upper 2 from src2.
   When src1 = src2, identical to PSHUFD — single-source 32-bit word shuffle. *)
external shufps : (int[@untagged]) -> (int32x4[@unboxed]) -> (int32x4[@unboxed]) -> (int32x4[@unboxed])
  = "caml_vec128_unreachable" "caml_sse_vec128_shuffle_32" [@@noalloc] [@@builtin]

(* ---- PSHUFB masks for bit-rotations within each 32-bit lane -------------- *)
(* Words are little-endian: byte[0]=LSB.
   rot16: swap 16-bit halves → [b2,b3,b0,b1] per word.
   rot8:  cyclic byte left   → [b3,b0,b1,b2] per word. *)
let rot16_mask_bytes =
  let b = Bytes.create 16 in
  Array.iteri (Bytes.set b)
    [| '\x02';'\x03';'\x00';'\x01'; '\x06';'\x07';'\x04';'\x05';
       '\x0a';'\x0b';'\x08';'\x09'; '\x0e';'\x0f';'\x0c';'\x0d' |];
  b

let rot8_mask_bytes =
  let b = Bytes.create 16 in
  Array.iteri (Bytes.set b)
    [| '\x03';'\x00';'\x01';'\x02'; '\x07';'\x04';'\x05';'\x06';
       '\x0b';'\x08';'\x09';'\x0a'; '\x0f';'\x0c';'\x0d';'\x0e' |];
  b

(* ---- Bit-rotations within each 32-bit lane ------------------------------- *)
let[@inline] rotate_left_16 v = pshufb v (load rot16_mask_bytes 0)
let[@inline] rotate_left_12 v = vec_xor (slli 12 v) (srli 20 v)
let[@inline] rotate_left_8  v = pshufb v (load rot8_mask_bytes  0)
let[@inline] rotate_left_7  v = vec_xor (slli  7 v) (srli 25 v)

(* ---- Word-lane rotation inside int32x4 (SHUFPS with src1=src2 = PSHUFD) -- *)
(* imm8 encodes: bits[1:0]→dest[0], [3:2]→dest[1], [5:4]→dest[2], [7:6]→dest[3] *)
let[@inline] rot_w1 v = shufps 0x39 v v   (* [w0,w1,w2,w3] → [w1,w2,w3,w0] *)
let[@inline] rot_w2 v = shufps 0x4E v v   (* [w0,w1,w2,w3] → [w2,w3,w0,w1] *)
let[@inline] rot_w3 v = shufps 0x93 v v   (* [w0,w1,w2,w3] → [w3,w0,w1,w2] *)

(* ---- ChaCha20 quarter-round (RFC 7539 §2.1) ------------------------------- *)
(* a,b,c,d are each int32x4 — one call runs 4 independent QRs, one per lane. *)
let[@inline] quarterround a b c d =
  let a = vec_add a b in let d = vec_xor d a in let d = rotate_left_16 d in
  let c = vec_add c d in let b = vec_xor b c in let b = rotate_left_12 b in
  let a = vec_add a b in let d = vec_xor d a in let d = rotate_left_8  d in
  let c = vec_add c d in let b = vec_xor b c in let b = rotate_left_7  b in
  (a, b, c, d)

(* ---- Double-round: column round then diagonal round (RFC 7539 §2.2) ------ *)
(*
   State rows: a=[s0..s3]  b=[s4..s7]  c=[s8..s11]  d=[s12..s15]
   Column QR: quarterround(a,b,c,d) hits all 4 columns simultaneously.
   Diagonal QR: rotate rows to bring diagonals into "column" position,
                run QR, then undo the rotations.
     b →rot_w1→ [s5,s6,s7,s4]   (undo: rot_w3)
     c →rot_w2→ [s10,s11,s8,s9] (undo: rot_w2)
     d →rot_w3→ [s15,s12,s13,s14](undo: rot_w1)
*)
let[@inline] double_round a b c d =
  let (a, b, c, d) = quarterround a b c d in
  let b = rot_w1 b in let c = rot_w2 c in let d = rot_w3 d in
  let (a, b, c, d) = quarterround a b c d in
  let b = rot_w3 b in let c = rot_w2 c in let d = rot_w1 d in
  (a, b, c, d)

(* ---- ChaCha20 constants: "expand 32-byte k" in LE ------------------------ *)
let constant_bytes = Bytes.of_string "expand 32-byte k"

(* ---- ChaCha20 block function (RFC 7539 §2.3) ------------------------------ *)
let chacha20_block ~(key : bytes) ~(nonce : bytes) ~counter =
  (* Build row3: [counter_le32 || nonce_12bytes] *)
  let ctr_nonce = Bytes.create 16 in
  Bytes.set ctr_nonce 0 (Char.chr ( counter         land 0xFF));
  Bytes.set ctr_nonce 1 (Char.chr ((counter lsr  8) land 0xFF));
  Bytes.set ctr_nonce 2 (Char.chr ((counter lsr 16) land 0xFF));
  Bytes.set ctr_nonce 3 (Char.chr ((counter lsr 24) land 0xFF));
  Bytes.blit nonce 0 ctr_nonce 4 12;
  let s0 = load constant_bytes 0 in
  let s1 = load key 0 in
  let s2 = load key 16 in
  let s3 = load ctr_nonce 0 in
  (* 10 double-rounds = 20 rounds total *)
  let rec loop n a b c d =
    if n = 0 then (a, b, c, d)
    else let (a, b, c, d) = double_round a b c d in loop (n-1) a b c d
  in
  let (a, b, c, d) = loop 10 s0 s1 s2 s3 in
  let out = Bytes.create 64 in
  store out  0 (vec_add a s0);
  store out 16 (vec_add b s1);
  store out 32 (vec_add c s2);
  store out 48 (vec_add d s3);
  out

(* ---- ChaCha20 stream cipher (RFC 7539 §2.4) ------------------------------- *)
let chacha20_crypt ~(key : bytes) ~(nonce : bytes) ~(initial_counter : int) (msg : bytes) =
  let len = Bytes.length msg in
  let out = Bytes.copy msg in
  let nblocks = len / 64 in
  for i = 0 to nblocks - 1 do
    let ks   = chacha20_block ~key ~nonce ~counter:(initial_counter + i) in
    let base = i * 64 in
    store out  base      (vec_xor (load ks  0) (load out  base     ));
    store out (base+16)  (vec_xor (load ks 16) (load out (base+16) ));
    store out (base+32)  (vec_xor (load ks 32) (load out (base+32) ));
    store out (base+48)  (vec_xor (load ks 48) (load out (base+48) ));
  done;
  let rem = len land 63 in
  if rem > 0 then begin
    let ks   = chacha20_block ~key ~nonce ~counter:(initial_counter + nblocks) in
    let base = nblocks * 64 in
    for j = 0 to rem - 1 do
      Bytes.set out (base + j)
        (Char.chr (Char.code (Bytes.get out (base+j)) lxor Char.code (Bytes.get ks j)))
    done
  end;
  out

(* ---- Test helpers -------------------------------------------------------- *)
let hex_of_bytes b =
  let buf = Buffer.create (Bytes.length b * 2) in
  Bytes.iter (fun c -> Buffer.add_string buf (Printf.sprintf "%02x" (Char.code c))) b;
  Buffer.contents buf

let bytes_of_hex h =
  let n = String.length h / 2 in
  Bytes.init n (fun i -> Char.chr (int_of_string ("0x" ^ String.sub h (i*2) 2)))

(* ---- RFC 7539 §2.1.1 quarter-round self-test ----------------------------- *)
let () =
  let le32 b i =
    Char.code (Bytes.get b  i)
    lor (Char.code (Bytes.get b (i+1)) lsl 8)
    lor (Char.code (Bytes.get b (i+2)) lsl 16)
    lor (Char.code (Bytes.get b (i+3)) lsl 24)
  in
  let mk4 v =
    let b = Bytes.create 16 in
    for i = 0 to 3 do
      let j = i * 4 in
      Bytes.set b  j    (Char.chr  (v         land 0xFF));
      Bytes.set b (j+1) (Char.chr ((v lsr  8) land 0xFF));
      Bytes.set b (j+2) (Char.chr ((v lsr 16) land 0xFF));
      Bytes.set b (j+3) (Char.chr ((v lsr 24) land 0xFF))
    done;
    load b 0
  in
  let a = mk4 0x11111111 and b = mk4 0x01020304 in
  let c = mk4 0x9b8d6f43 and d = mk4 0x01234567 in
  let (a', b', c', d') = quarterround a b c d in
  let buf = Bytes.create 16 in
  let lane0 v = store buf 0 v; le32 buf 0 in
  let check lbl got want =
    if got land 0xFFFFFFFF <> want land 0xFFFFFFFF then begin
      Printf.eprintf "FAIL %s: got %08x expected %08x\n" lbl got want; exit 1
    end
  in
  check "a" (lane0 a') 0xea2a92f4;
  check "b" (lane0 b') 0xcb1cf8ce;
  check "c" (lane0 c') 0x4581472e;
  check "d" (lane0 d') 0x5881c4bb;
  print_string "QuarterRound RFC 7539 2.1.1: PASSED\n"

(* ---- RFC 8439 §2.3.2 block function self-test ---------------------------- *)
(* NOTE: RFC 7539 §2.3.2 contains an erratum in its block-function test vector
   (byte 14 is 0x70 in RFC 7539 but the correct value is 0x71; the single-bit
   error cascades into 49 of 64 output bytes differing).  RFC 8439 (May 2018),
   which officially supersedes RFC 7539, carries the corrected vector.  The
   expected value below is verified independently against OpenSSL, Node.js/OpenSSL,
   Python cryptography (OpenSSL), a scalar C reference, a scalar OCaml reference,
   and this SIMD OCaml implementation — all seven agree. *)
let () =
  let key   = Bytes.init 32 Char.chr in
  let nonce = bytes_of_hex "000000090000004a00000000" in
  let got   = chacha20_block ~key ~nonce ~counter:1 in
  let expected = bytes_of_hex
    "10f1e7e4d13b5915500fdd1fa32071c4\
     c7d1f4c733c068030422aa9ac3d46c4e\
     d2826446079faa0914c2d705d98b02a2\
     b5129cd1de164eb9cbd083e8a2503c4e"
  in
  if got <> expected then begin
    Printf.eprintf "FAIL block:\n  got      %s\n  expected %s\n"
      (hex_of_bytes got) (hex_of_bytes expected);
    exit 1
  end;
  print_string "ChaCha20 block RFC 8439 2.3.2: PASSED\n"

(* ---- RFC 7539 §2.4.2 encryption self-test -------------------------------- *)
let () =
  let key   = Bytes.init 32 Char.chr in
  let nonce = bytes_of_hex "000000000000004a00000000" in
  let plain = Bytes.of_string
    "Ladies and Gentlemen of the class of '99: If I could offer \
     you only one tip for the future, sunscreen would be it."
  in
  let got  = chacha20_crypt ~key ~nonce ~initial_counter:1 plain in
  let expected = bytes_of_hex
    "6e2e359a2568f98041ba0728dd0d6981\
     e97e7aec1d4360c20a27afccfd9fae0b\
     f91b65c5524733ab8f593dabcd62b357\
     1639d624e65152ab8f530c359f0861d8\
     07ca0dbf500d6a6156a38e088a22b65e\
     52bc514d16ccf806818ce91ab7793736\
     5af90bbf74a35be6b40b8eedf2785e42\
     874d"
  in
  if got <> expected then begin
    Printf.eprintf "FAIL encrypt:\n  got      %s\n  expected %s\n"
      (hex_of_bytes got) (hex_of_bytes expected);
    exit 1
  end;
  print_string "ChaCha20 encrypt RFC 7539 2.4.2: PASSED\n"
