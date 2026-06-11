val init_inv_sbox : unit -> unit

val key_expansion :
  int array ->
  int array array ->
  unit

val aes_encrypt_buffer :
  bytes ->
  bytes ->
  int ->
  int array array ->
  unit

val aes_decrypt_buffer :
  bytes ->
  bytes ->
  int ->
  int array array ->
  unit