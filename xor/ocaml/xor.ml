let xor_encrypt message key =
  let msg_len = Bytes.length message in
  let key_len = Bytes.length key in
  let output = Bytes.create msg_len in

  for i = 0 to msg_len - 1 do
    let m = Char.code (Bytes.get message i) in
    let k = Char.code (Bytes.get key (i mod key_len)) in
    Bytes.set output i (Char.chr (m lxor k))
  done;

  output

let xor_decrypt ciphertext key =
  let cipher_len = Bytes.length ciphertext in
  let key_len = Bytes.length key in
  let output = Bytes.create cipher_len in

  for i = 0 to cipher_len - 1 do
    let c = Char.code (Bytes.get ciphertext i) in
    let k = Char.code (Bytes.get key (i mod key_len)) in
    Bytes.set output i (Char.chr (c lxor k))
  done;

  output