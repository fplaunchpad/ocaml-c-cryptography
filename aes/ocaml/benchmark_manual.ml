
let () =
  if Array.length Sys.argv <> 2 then begin
    Printf.printf "Usage: %s <input_file>\n"
      Sys.argv.(0);
    exit 1
  end;

let input_file = Sys.argv.(1) in

let ic = open_in_bin input_file in
let msg_len = in_channel_length ic in
let padded_len = ((msg_len + 15) / 16) * 16 in

let message = Bytes.make padded_len '\000' in

really_input ic message 0 msg_len;

close_in ic;

let kf = open_in_bin "../benchmarks/key.txt" in

let key_bytes = Bytes.create 16 in

really_input kf key_bytes 0 16;

close_in kf;

let key =
  Array.init 16
    (fun i ->
       Char.code
         (Bytes.get key_bytes i))
in

Aes_manual.init_inv_sbox ();

let words = Array.make_matrix 44 4 0 in

Aes_manual.key_expansion key words;

  let encrypted =
  Bytes.create padded_len
in

let decrypted =
  Bytes.create padded_len
in

let enc_start =
  Unix.gettimeofday ()
in

Aes_manual.aes_encrypt_buffer
  message
  encrypted
  padded_len
  words;

let enc_end =
  Unix.gettimeofday ()
in

let dec_start =
  Unix.gettimeofday ()
in

Aes_manual.aes_decrypt_buffer
  encrypted
  decrypted
  padded_len
  words;

let dec_end = Unix.gettimeofday () in

let ok = ref true in

for i = 0 to msg_len - 1 do
  if Bytes.get message i <>
     Bytes.get decrypted i
  then
    ok := false
done;

let enc_time = enc_end -. enc_start in

let dec_time = dec_end -. dec_start in

let size_mb = float_of_int msg_len /. (1024.0 *. 1024.0) in

let enc_speed = size_mb /. enc_time in

let dec_speed = size_mb /. dec_time in

Printf.printf
  "Message length      : %d bytes\n"
  msg_len;

Printf.printf
  "Encryption time     : %.6f sec\n"
  enc_time;

Printf.printf
  "Decryption time     : %.6f sec\n"
  dec_time;

Printf.printf
  "Encryption speed    : %.2f MB/s\n"
  enc_speed;

Printf.printf
  "Decryption speed    : %.2f MB/s\n"
  dec_speed;

Printf.printf
  "Verification        : %s\n"
  (if !ok then "PASSED"
   else "FAILED");