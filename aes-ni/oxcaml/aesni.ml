(** OCaml interface to AES-NI hardware acceleration.
    Stubs follow the Cryptokit convention by Xavier Leroy. *)

(** Returns 1 if the CPU supports AES-NI, 0 otherwise. *)
external check_available : unit -> int
  = "caml_aesni_check"

(** [cook_encrypt_key key] expands [key] (16/24/32 bytes) into an
    encryption key schedule stored as a bytes value. *)
external cook_encrypt_key : bytes -> bytes
  = "caml_aes_cook_encrypt_key"

(** [cook_decrypt_key key] expands [key] into a decryption key schedule. *)
external cook_decrypt_key : bytes -> bytes
  = "caml_aes_cook_decrypt_key"

(** [encrypt_block ckey src src_off dst dst_off] encrypts the 16-byte
    block at [src.[src_off..src_off+15]] into [dst.[dst_off..dst_off+15]]. *)
external encrypt_block : bytes -> bytes -> int -> bytes -> int -> unit
  = "caml_aes_encrypt"

(** [decrypt_block ckey src src_off dst dst_off] decrypts one block. *)
external decrypt_block : bytes -> bytes -> int -> bytes -> int -> unit
  = "caml_aes_decrypt"
