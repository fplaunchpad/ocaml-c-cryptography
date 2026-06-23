(** AES-NI benchmark using OCaml C bindings.
    Stubs follow the Cryptokit pattern by Xavier Leroy. *)

open Aesni

let benchmark_file filename =
  if check_available () = 0 then begin
    Printf.eprintf "AES-NI not supported on this CPU\n";
    exit 1
  end;

  let ic = open_in_bin filename in
  let original_len = in_channel_length ic in
  let data = Bytes.create original_len in
  really_input ic data 0 original_len;
  close_in ic;

  let original_data = Bytes.copy data in

  let padded_len = ((original_len + 15) / 16) * 16 in
  let padded = Bytes.make padded_len '\000' in
  Bytes.blit data 0 padded 0 original_len;

  (* Fixed 16-byte key matching the C benchmark *)
  let key = Bytes.of_string
    "\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f" in

  let ckey_enc = cook_encrypt_key key in
  let ckey_dec = cook_decrypt_key key in

  let nblocks   = padded_len / 16 in
  let encrypted = Bytes.create padded_len in
  let decrypted = Bytes.create padded_len in

  (* Encrypt: OCaml loop, one C call per 16-byte block (cryptokit pattern) *)
  let enc_start = Unix.gettimeofday () in
  for i = 0 to nblocks - 1 do
    let off = i * 16 in
    encrypt_block ckey_enc padded off encrypted off
  done;
  let enc_end = Unix.gettimeofday () in

  (* Decrypt *)
  let dec_start = Unix.gettimeofday () in
  for i = 0 to nblocks - 1 do
    let off = i * 16 in
    decrypt_block ckey_dec encrypted off decrypted off
  done;
  let dec_end = Unix.gettimeofday () in

  let enc_time = enc_end -. enc_start in
  let dec_time = dec_end -. dec_start in
  let mb       = float_of_int original_len /. (1024.0 *. 1024.0) in
  let size_mb  = int_of_float mb in

  (* Verify round-trip *)
  let ok = ref true in
  for i = 0 to original_len - 1 do
    if Bytes.get original_data i <> Bytes.get decrypted i then ok := false
  done;
  if not !ok then begin
    Printf.eprintf "Verification: FAILED\n";
    exit 1
  end;

  Printf.printf "%d,%.6f,%.6f,%.2f,%.2f\n"
    size_mb enc_time dec_time (mb /. enc_time) (mb /. dec_time)

let () =
  if Array.length Sys.argv <> 2 then begin
    Printf.eprintf "Usage: %s <input_file>\n" Sys.argv.(0);
    exit 1
  end;
  benchmark_file Sys.argv.(1)
