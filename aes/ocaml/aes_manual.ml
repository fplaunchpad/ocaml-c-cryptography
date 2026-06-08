let add_round_key state key =
  for i = 0 to 3 do
    for j = 0 to 3 do
      state.(i).(j) <-
        state.(i).(j) lxor key.(i).(j)
    done
  done

let xtime x =
  if (x land 0x80) <> 0 then
    ((x lsl 1) land 0xFF) lxor 0x1B
  else
    (x lsl 1) land 0xFF

let mul2 x =
  xtime x

let mul3 x =
  (xtime x) lxor x

let mul4 x =
  mul2 (mul2 x)

let mul8 x =
  mul2 (mul4 x)

let mul9 x =
  (mul8 x) lxor x

let mul11 x =
  (mul8 x) lxor (mul2 x) lxor x

let mul13 x =
  (mul8 x) lxor (mul4 x) lxor x

let mul14 x =
  (mul8 x) lxor (mul4 x) lxor (mul2 x)
  
let sbox = [|
  0x63;0x7c;0x77;0x7b;0xf2;0x6b;0x6f;0xc5;
  0x30;0x01;0x67;0x2b;0xfe;0xd7;0xab;0x76;

  0xca;0x82;0xc9;0x7d;0xfa;0x59;0x47;0xf0;
  0xad;0xd4;0xa2;0xaf;0x9c;0xa4;0x72;0xc0;

  0xb7;0xfd;0x93;0x26;0x36;0x3f;0xf7;0xcc;
  0x34;0xa5;0xe5;0xf1;0x71;0xd8;0x31;0x15;

  0x04;0xc7;0x23;0xc3;0x18;0x96;0x05;0x9a;
  0x07;0x12;0x80;0xe2;0xeb;0x27;0xb2;0x75;

  0x09;0x83;0x2c;0x1a;0x1b;0x6e;0x5a;0xa0;
  0x52;0x3b;0xd6;0xb3;0x29;0xe3;0x2f;0x84;

  0x53;0xd1;0x00;0xed;0x20;0xfc;0xb1;0x5b;
  0x6a;0xcb;0xbe;0x39;0x4a;0x4c;0x58;0xcf;

  0xd0;0xef;0xaa;0xfb;0x43;0x4d;0x33;0x85;
  0x45;0xf9;0x02;0x7f;0x50;0x3c;0x9f;0xa8;

  0x51;0xa3;0x40;0x8f;0x92;0x9d;0x38;0xf5;
  0xbc;0xb6;0xda;0x21;0x10;0xff;0xf3;0xd2;

  0xcd;0x0c;0x13;0xec;0x5f;0x97;0x44;0x17;
  0xc4;0xa7;0x7e;0x3d;0x64;0x5d;0x19;0x73;

  0x60;0x81;0x4f;0xdc;0x22;0x2a;0x90;0x88;
  0x46;0xee;0xb8;0x14;0xde;0x5e;0x0b;0xdb;

  0xe0;0x32;0x3a;0x0a;0x49;0x06;0x24;0x5c;
  0xc2;0xd3;0xac;0x62;0x91;0x95;0xe4;0x79;

  0xe7;0xc8;0x37;0x6d;0x8d;0xd5;0x4e;0xa9;
  0x6c;0x56;0xf4;0xea;0x65;0x7a;0xae;0x08;

  0xba;0x78;0x25;0x2e;0x1c;0xa6;0xb4;0xc6;
  0xe8;0xdd;0x74;0x1f;0x4b;0xbd;0x8b;0x8a;

  0x70;0x3e;0xb5;0x66;0x48;0x03;0xf6;0x0e;
  0x61;0x35;0x57;0xb9;0x86;0xc1;0x1d;0x9e;

  0xe1;0xf8;0x98;0x11;0x69;0xd9;0x8e;0x94;
  0x9b;0x1e;0x87;0xe9;0xce;0x55;0x28;0xdf;

  0x8c;0xa1;0x89;0x0d;0xbf;0xe6;0x42;0x68;
  0x41;0x99;0x2d;0x0f;0xb0;0x54;0xbb;0x16;
|]

let inv_sbox =
  Array.make 256 0

let init_inv_sbox () =
  for i = 0 to 255 do
    inv_sbox.(sbox.(i)) <- i
  done

let sub_bytes state =
  for i = 0 to 3 do
    for j = 0 to 3 do
      state.(i).(j) <-
        sbox.(state.(i).(j))
    done
  done

let inv_sub_bytes state =
  for i = 0 to 3 do
    for j = 0 to 3 do
      state.(i).(j) <-
        inv_sbox.(state.(i).(j))
    done
  done

let shift_rows state =
  let temp = state.(1).(0) in
  for j = 0 to 2 do
    state.(1).(j) <- state.(1).(j + 1)
  done;
  state.(1).(3) <- temp;

  let temp1 = state.(2).(0) in
  let temp2 = state.(2).(1) in
  state.(2).(0) <- state.(2).(2);
  state.(2).(1) <- state.(2).(3);
  state.(2).(2) <- temp1;
  state.(2).(3) <- temp2;

  let temp = state.(3).(3) in
  for j = 3 downto 1 do
    state.(3).(j) <- state.(3).(j - 1)
  done;
  state.(3).(0) <- temp

let inv_shift_rows state =
  let temp = state.(1).(3) in

  for j = 3 downto 1 do
    state.(1).(j) <- state.(1).(j - 1)
  done;

  state.(1).(0) <- temp;

  let temp1 = state.(2).(2) in
  let temp2 = state.(2).(3) in

  state.(2).(3) <- state.(2).(1);
  state.(2).(2) <- state.(2).(0);
  state.(2).(1) <- temp2;
  state.(2).(0) <- temp1;

  let temp = state.(3).(0) in

  for j = 0 to 2 do
    state.(3).(j) <- state.(3).(j + 1)
  done;

  state.(3).(3) <- temp

let mix_single_column col =
  let a = col.(0) in
  let b = col.(1) in
  let c = col.(2) in
  let d = col.(3) in

  col.(0) <- (mul2 a) lxor (mul3 b) lxor c lxor d;
  col.(1) <- a lxor (mul2 b) lxor (mul3 c) lxor d;
  col.(2) <- a lxor b lxor (mul2 c) lxor (mul3 d);
  col.(3) <- (mul3 a) lxor b lxor c lxor (mul2 d)

let inv_mix_single_column col =
  let a = col.(0) in
  let b = col.(1) in
  let c = col.(2) in
  let d = col.(3) in

  col.(0) <- (mul14 a) lxor (mul11 b) lxor (mul13 c) lxor (mul9 d);
  col.(1) <- (mul9 a)  lxor (mul14 b) lxor (mul11 c) lxor (mul13 d);
  col.(2) <- (mul13 a) lxor (mul9 b)  lxor (mul14 c) lxor (mul11 d);
  col.(3) <- (mul11 a) lxor (mul13 b) lxor (mul9 c)  lxor (mul14 d)

let mix_columns state =
  for j = 0 to 3 do
    let col =
      [|
        state.(0).(j);
        state.(1).(j);
        state.(2).(j);
        state.(3).(j)
      |]
    in

    mix_single_column col;

    for i = 0 to 3 do
      state.(i).(j) <- col.(i)
    done
  done

let inv_mix_columns state =
  for j = 0 to 3 do
    let col =
      [|
        state.(0).(j);
        state.(1).(j);
        state.(2).(j);
        state.(3).(j)
      |]
    in

    inv_mix_single_column col;

    for i = 0 to 3 do
      state.(i).(j) <- col.(i)
    done
  done

let rcon = [|
  0x01;
  0x02;
  0x04;
  0x08;
  0x10;
  0x20;
  0x40;
  0x80;
  0x1B;
  0x36
|]

let rot_word word =
  let temp = word.(0) in

  word.(0) <- word.(1);
  word.(1) <- word.(2);
  word.(2) <- word.(3);
  word.(3) <- temp

let sub_word word =
  for i = 0 to 3 do
    word.(i) <- sbox.(word.(i))
  done

let g word round =
  rot_word word;
  sub_word word;
  word.(0) <- word.(0) lxor rcon.(round)

let key_expansion key words =
  for j = 0 to 3 do
    words.(0).(j) <- key.(j);
    words.(1).(j) <- key.(4 + j);
    words.(2).(j) <- key.(8 + j);
    words.(3).(j) <- key.(12 + j)
  done;

  for i = 4 to 43 do
    let temp = Array.copy words.(i - 1) in

    if i mod 4 = 0 then
      g temp ((i / 4) - 1);

    for j = 0 to 3 do
      words.(i).(j) <-
        words.(i - 4).(j) lxor temp.(j)
    done
  done

let aes_round state round_key =
  sub_bytes state;
  shift_rows state;
  mix_columns state;
  add_round_key state round_key

let final_round state round_key =
  sub_bytes state;
  shift_rows state;
  add_round_key state round_key

let build_round_key words round rk =
  let start = round * 4 in

  for i = 0 to 3 do
    for j = 0 to 3 do
      rk.(i).(j) <- words.(start + i).(j)
    done
  done

let aes128_encrypt state words =
  let rk =
    Array.make_matrix 4 4 0
  in

  build_round_key words 0 rk;
  add_round_key state rk;

  for round = 1 to 9 do
    build_round_key words round rk;
    aes_round state rk
  done;

  build_round_key words 10 rk;
  final_round state rk

let aes128_decrypt state words =
  let rk =
    Array.make_matrix 4 4 0
  in

  build_round_key words 10 rk;
  add_round_key state rk;

  inv_shift_rows state;
  inv_sub_bytes state;

  for round = 9 downto 1 do
    build_round_key words round rk;

    add_round_key state rk;
    inv_mix_columns state;
    inv_shift_rows state;
    inv_sub_bytes state
  done;

  build_round_key words 0 rk;
  add_round_key state rk

let aes_encrypt_buffer input output len words =
  if len mod 16 <> 0 then begin
    Printf.printf "Length must be multiple of 16\n";
    exit 1
  end;

  let block = ref 0 in

  while !block < len do
    let state =
      Array.make_matrix 4 4 0
    in

    for i = 0 to 3 do
      for j = 0 to 3 do
        state.(i).(j) <-
          Char.code
            (Bytes.get input
               (!block + i * 4 + j))
      done
    done;

    aes128_encrypt state words;

    for i = 0 to 3 do
      for j = 0 to 3 do
        Bytes.set output
          (!block + i * 4 + j)
          (Char.chr state.(i).(j))
      done
    done;

    block := !block + 16
  done

let aes_decrypt_buffer input output len words =
  if len mod 16 <> 0 then begin
    Printf.printf "Length must be multiple of 16\n";
    exit 1
  end;

  let block = ref 0 in

  while !block < len do
    let state =
      Array.make_matrix 4 4 0
    in

    for i = 0 to 3 do
      for j = 0 to 3 do
        state.(i).(j) <-
          Char.code
            (Bytes.get input
               (!block + i * 4 + j))
      done
    done;

    aes128_decrypt state words;

    for i = 0 to 3 do
      for j = 0 to 3 do
        Bytes.set output
          (!block + i * 4 + j)
          (Char.chr state.(i).(j))
      done
    done;

    block := !block + 16
  done
  