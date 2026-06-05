let read_file filename =
  let ic = open_in_bin filename in
  let len = in_channel_length ic in
  let data = Bytes.create len in
  really_input ic data 0 len;
  close_in ic;
  data

let write_file filename data =
  let oc = open_out_bin filename in
  output_bytes oc data;
  close_out oc

let () =
  if Array.length Sys.argv <> 2 then begin
    Printf.printf "Usage: %s <input_file>\n" Sys.argv.(0);
    exit 1
  end;

  let input_file = Sys.argv.(1) in

  let message = read_file input_file in
  let key = read_file "../benchmarks/key.txt" in

  let encrypted = ref (Bytes.create 0) in

  let enc_start = Unix.gettimeofday () in

  for _ = 1 to 10 do
    encrypted := Xor.xor_encrypt message key
  done;

  let enc_end = Unix.gettimeofday () in

  write_file "../benchmarks/ciphertext.bin" !encrypted;

  let decrypted = ref (Bytes.create 0) in

  let dec_start = Unix.gettimeofday () in

  for _ = 1 to 10 do
    decrypted := Xor.xor_decrypt !encrypted key
  done;

  let dec_end = Unix.gettimeofday () in

  write_file "../benchmarks/decrypted.txt" !decrypted;

  let ok = Bytes.equal message !decrypted in

  let msg_len = Bytes.length message in

  let enc_time = (enc_end -. enc_start) /. 10.0 in
  let dec_time = (dec_end -. dec_start) /. 10.0 in

  let size_mb =
    float_of_int msg_len /. (1024.0 *. 1024.0)
  in

  let enc_speed = size_mb /. enc_time in
  let dec_speed = size_mb /. dec_time in

  Printf.printf "Message length      : %d bytes\n" msg_len;
  Printf.printf "Key length          : %d bytes\n"
    (Bytes.length key);

  Printf.printf "Encryption time     : %.6f sec\n"
    enc_time;

  Printf.printf "Decryption time     : %.6f sec\n"
    dec_time;

  Printf.printf "Encryption speed    : %.2f MB/s\n"
    enc_speed;

  Printf.printf "Decryption speed    : %.2f MB/s\n"
    dec_speed;

  Printf.printf "Verification        : %s\n"
    (if ok then "PASSED" else "FAILED")