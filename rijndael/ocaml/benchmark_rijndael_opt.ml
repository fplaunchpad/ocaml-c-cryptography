open Rijndael_fst_opt

let benchmark_file filename =
  let ic = open_in_bin filename in
  let len = in_channel_length ic in

  let data = Bytes.create len in
  really_input ic data 0 len;
  close_in ic;
  let original_data = Bytes.copy data in
  let original_len = len in

  let padded_len =
    ((len + 15) / 16) * 16
  in

  let padded_data = Bytes.make padded_len '\000' in
  Bytes.blit data 0 padded_data 0 len;

  let data = padded_data in
  let len = padded_len in

  let kf = open_in_bin "../benchmarks/key.txt" in
  let key = Bytes.create 16 in
  really_input kf key 0 16;
  close_in kf;

  let rk = Array.make 60 0l in
  let nr = key_setup_enc rk key 128 in

  let output = Bytes.create len in

  let start_time = Unix.gettimeofday () in

  for i = 0 to (len / 16) - 1 do
    let off = i * 16 in
    ignore (encrypt_block_off rk nr data off output off)
  done;

  let end_time = Unix.gettimeofday () in

  let elapsed = end_time -. start_time in

  let mb =
    float_of_int original_len /. (1024.0 *. 1024.0)
  in

let drk = Array.make 60 0l in
let dnr = key_setup_dec drk key 128 in

let recovered = Bytes.create len in
let dec_start = Unix.gettimeofday () in

for i = 0 to (len / 16) - 1 do
  let off = i * 16 in
  ignore (decrypt_block_off drk dnr output off recovered off)
done;

let dec_end = Unix.gettimeofday () in

let dec_time = dec_end -. dec_start in

let enc_speed = mb /. elapsed in
let dec_speed = mb /. dec_time in

let size_mb =
  int_of_float mb
in
let ok = ref true in

for i = 0 to original_len - 1 do
  if Bytes.get original_data i <> Bytes.get recovered i then
    ok := false
done;

if not !ok then begin
  Printf.eprintf "Verification: FAILED\n";
  exit 1
end;

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

