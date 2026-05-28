let xor_encrypt message key =
    let key_len = String.length key in
    String.init (String.length message)
        (fun i ->
            Char.chr(
                (Char.code message.[i])
                lxor
                (Char.code key.[i mod key_len])
            )
        )

let () =

    let base =
        "CryptographyAndFunctionalProgrammingResearch123"
    in

    let message =
        String.concat "" (Array.to_list (Array.make 100000 base))
    in

    let key = "securekey" in

    let encrypted = xor_encrypt message key in

    let decrypted = xor_encrypt encrypted key in

    print_endline ("Message length: " ^
        string_of_int (String.length message));

    print_endline "Encryption completed";

    print_endline ("Decryption correct: " ^
        string_of_bool (message = decrypted))