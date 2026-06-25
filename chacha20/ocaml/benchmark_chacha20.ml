open Chacha20

let read_file path =
  let ic = open_in_bin path in
  let n = in_channel_length ic in
  let buf = Bytes.create n in
  really_input ic buf 0 n;
  close_in ic;
  buf

let () =
  if Array.length Sys.argv <> 4 then begin
    Printf.eprintf "Usage: %s <input_file> <key_file> <nonce_file>\n" Sys.argv.(0);
    exit 1
  end;

  let message    = read_file Sys.argv.(1) in
  let key        = read_file Sys.argv.(2) in
  let nonce      = read_file Sys.argv.(3) in
  let msg_len    = Bytes.length message in
  let counter    = 0L in
  let ciphertext = Bytes.create msg_len in
  let decrypted  = Bytes.create msg_len in
  let ctx        = create () in

  (* Timed encryption *)
  init ctx key nonce counter;
  let enc_start = Unix.gettimeofday () in
  transform ctx message ciphertext msg_len;
  let enc_end = Unix.gettimeofday () in

  (* Timed decryption — ChaCha20 is symmetric, same op with same key/nonce/counter *)
  init ctx key nonce counter;
  let dec_start = Unix.gettimeofday () in
  transform ctx ciphertext decrypted msg_len;
  let dec_end = Unix.gettimeofday () in

  (* Correctness check — outside timed sections *)
  let ok = message = decrypted in

  let enc_time = enc_end -. enc_start in
  let dec_time = dec_end -. dec_start in
  let mb = float_of_int msg_len /. (1024.0 *. 1024.0) in

  Printf.printf "Message length      : %d bytes\n" msg_len;
  Printf.printf "Encryption time     : %.6f sec\n"  enc_time;
  Printf.printf "Decryption time     : %.6f sec\n"  dec_time;
  Printf.printf "Encryption speed    : %.2f MB/s\n" (mb /. enc_time);
  Printf.printf "Decryption speed    : %.2f MB/s\n" (mb /. dec_time);
  Printf.printf "Correctness         : %s\n"         (if ok then "PASSED" else "FAILED")
