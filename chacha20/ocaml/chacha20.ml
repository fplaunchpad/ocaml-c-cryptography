(* Pure OCaml translation of Bernstein's chacha-regs.c (public domain) *)

let[@inline] mask32 x = x land 0xFFFFFFFF

let[@inline] u8to32_le (buf : bytes) pos =
  Char.code (Bytes.unsafe_get buf  pos)
  lor (Char.code (Bytes.unsafe_get buf (pos + 1)) lsl 8)
  lor (Char.code (Bytes.unsafe_get buf (pos + 2)) lsl 16)
  lor (Char.code (Bytes.unsafe_get buf (pos + 3)) lsl 24)

let[@inline] u32to8_le (buf : bytes) pos v =
  Bytes.unsafe_set buf  pos       (Char.unsafe_chr  (v          land 0xFF));
  Bytes.unsafe_set buf (pos + 1)  (Char.unsafe_chr ((v lsr  8)  land 0xFF));
  Bytes.unsafe_set buf (pos + 2)  (Char.unsafe_chr ((v lsr 16)  land 0xFF));
  Bytes.unsafe_set buf (pos + 3)  (Char.unsafe_chr ((v lsr 24)  land 0xFF))

let[@inline] rotate v c =
  let v = mask32 v in
  mask32 ((v lsl c) lor (v lsr (32 - c)))

type ctx = {
  input    : int array;   (* 16 × uint32 state words *)
  output   : bytes;       (* 64-byte keystream block *)
  work     : int array;   (* scratch space for block function *)
  mutable next      : int;
  mutable iv_length : int;
}

let create () = {
  input = Array.make 16 0;
  output = Bytes.make 64 '\000';
  work = Array.make 16 0;
  next = 64;
  iv_length = 12;
}

let[@inline] quarterround (x : int array) a b c d =
  let va = mask32 (x.(a) + x.(b)) in x.(a) <- va;
  let vd = rotate (x.(d) lxor va) 16 in x.(d) <- vd;
  let vc = mask32 (x.(c) + vd) in x.(c) <- vc;
  let vb = rotate (x.(b) lxor vc) 12 in x.(b) <- vb;
  let va = mask32 (va + vb) in x.(a) <- va;
  let vd = rotate (vd lxor va) 8 in x.(d) <- vd;
  let vc = mask32 (vc + vd) in x.(c) <- vc;
  x.(b) <- rotate (vb lxor vc) 7

let chacha20_block ctx =
  let w = ctx.work in
  Array.blit ctx.input 0 w 0 16;
  for _ = 1 to 10 do
    quarterround w 0 4  8 12;
    quarterround w 1 5  9 13;
    quarterround w 2 6 10 14;
    quarterround w 3 7 11 15;
    quarterround w 0 5 10 15;
    quarterround w 1 6 11 12;
    quarterround w 2 7  8 13;
    quarterround w 3 4  9 14;
  done;
  for i = 0 to 15 do
    u32to8_le ctx.output (i * 4) (mask32 (w.(i) + ctx.input.(i)))
  done;
  let ctr = mask32 (ctx.input.(12) + 1) in
  ctx.input.(12) <- ctr;
  if ctr = 0 && ctx.iv_length = 8 then
    ctx.input.(13) <- mask32 (ctx.input.(13) + 1)

let constants32 = Bytes.of_string "expand 32-byte k"
let constants16 = Bytes.of_string "expand 16-byte k"

let init ctx (key : bytes) (nonce : bytes) (counter : int64) =
  let cs = if Bytes.length key = 32 then constants32 else constants16 in
  ctx.input.(0) <- u8to32_le cs 0;
  ctx.input.(1) <- u8to32_le cs 4;
  ctx.input.(2) <- u8to32_le cs 8;
  ctx.input.(3) <- u8to32_le cs 12;
  ctx.input.(4) <- u8to32_le key 0;
  ctx.input.(5) <- u8to32_le key 4;
  ctx.input.(6) <- u8to32_le key 8;
  ctx.input.(7) <- u8to32_le key 12;
  let off = if Bytes.length key = 32 then 16 else 0 in
  ctx.input.(8)  <- u8to32_le key (off + 0);
  ctx.input.(9)  <- u8to32_le key (off + 4);
  ctx.input.(10) <- u8to32_le key (off + 8);
  ctx.input.(11) <- u8to32_le key (off + 12);
  ctx.input.(12) <- mask32 (Int64.to_int counter);
  let nlen = Bytes.length nonce in
  if nlen = 8 then begin
    ctx.input.(13) <- mask32 (Int64.to_int (Int64.shift_right_logical counter 32));
    ctx.input.(14) <- u8to32_le nonce 0;
    ctx.input.(15) <- u8to32_le nonce 4;
  end else begin
    ctx.input.(13) <- u8to32_le nonce 0;
    ctx.input.(14) <- u8to32_le nonce 4;
    ctx.input.(15) <- u8to32_le nonce 8;
  end;
  ctx.iv_length <- nlen;
  ctx.next <- 64

let transform ctx (src : bytes) (dst : bytes) len =
  let n = ref ctx.next in
  for i = 0 to len - 1 do
    if !n >= 64 then begin chacha20_block ctx; n := 0 end;
    Bytes.unsafe_set dst i
      (Char.unsafe_chr
        (Char.code (Bytes.unsafe_get src i)
         lxor Char.code (Bytes.unsafe_get ctx.output !n)));
    incr n
  done;
  ctx.next <- !n
