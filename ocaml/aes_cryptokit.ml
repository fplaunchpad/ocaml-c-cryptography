open Cryptokit

let () =
  let key = "0123456789abcdef" in
  let plaintext = "abcdefghijklmnop" in

  let encrypt_cipher =
    Cipher.aes ~mode:Cipher.ECB key Encrypt
  in

  let decrypt_cipher =
    Cipher.aes ~mode:Cipher.ECB key Decrypt
  in

  let ciphertext =
    transform_string encrypt_cipher plaintext
  in

  (* Encryption benchmark *)
  let start_enc = Sys.time () in

  for _ = 1 to 1_000_000 do
    ignore (transform_string encrypt_cipher plaintext)
  done;

  let end_enc = Sys.time () in

  (* Decryption benchmark *)
  let start_dec = Sys.time () in

  for _ = 1 to 1_000_000 do
    ignore (transform_string decrypt_cipher ciphertext)
  done;

  let end_dec = Sys.time () in

  Printf.printf "AES encryptions: 1000000\n";
  Printf.printf "Encryption Time: %.6f sec\n\n"
    (end_enc -. start_enc);

  Printf.printf "AES decryptions: 1000000\n";
  Printf.printf "Decryption Time: %.6f sec\n"
    (end_dec -. start_dec);