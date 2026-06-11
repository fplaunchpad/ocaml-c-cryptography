open Rijndael_fst

let benchmark_file filename =
  let ic = open_in_bin filename in
  let len = in_channel_length ic in

  let data = Bytes.create len in
  really_input ic data 0 len;
  close_in ic;

  let key = Bytes.make 16 '\000' in

  let rk = Array.make 60 0l in
  let nr = key_setup_enc rk key 128 in

  let output = Bytes.create len in

  let start_time = Unix.gettimeofday () in

  for i = 0 to (len / 16) - 1 do
    let block = Bytes.sub data (i * 16) 16 in
    let out_block = Bytes.create 16 in

    ignore (encrypt_block rk nr block out_block);

    Bytes.blit out_block 0 output (i * 16) 16
  done;

  let end_time = Unix.gettimeofday () in

  let elapsed = end_time -. start_time in

  let mb =
    float_of_int len /. (1024.0 *. 1024.0)
  in

let drk = Array.make 60 0l in
let dnr = key_setup_dec drk key 128 in

let recovered = Bytes.create len in

let dec_start = Unix.gettimeofday () in

for i = 0 to (len / 16) - 1 do
  let block = Bytes.sub output (i * 16) 16 in
  let out_block = Bytes.create 16 in

  ignore (decrypt_block drk dnr block out_block);

  Bytes.blit out_block 0 recovered (i * 16) 16
done;

let dec_end = Unix.gettimeofday () in

let dec_time = dec_end -. dec_start in

let enc_speed = mb /. elapsed in
let dec_speed = mb /. dec_time in

let size_mb =
  int_of_float mb
in

Printf.printf
  "%d,%.6f,%.6f,%.2f,%.2f\n"
  size_mb
  elapsed
  dec_time
  enc_speed
  dec_speed

let () =
  if Array.length Sys.argv <> 2 then begin
    Printf.eprintf "Usage: %s <input_file>\n" Sys.argv.(0);
    exit 1
  end;

  benchmark_file Sys.argv.(1)