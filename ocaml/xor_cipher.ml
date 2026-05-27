let xor_encrypt message key =
    let key_len = String.length key in
    String.init (String.length message)
        (fun i->
            Char.chr(
                (Char.code message.[i])
                lxor
                (Char.code key.[i mod key_len])
            )
        )

    let () =
        print_string("enter message:");
        let message=read_line()in

        print_string "enter key:";
        let key=read_line()in

        let encrypted=xor_encrypt message key in
        print_endline("encrypted message:"^encrypted);

        let decrypted=xor_encrypt encrypted key in
        print_endline("decrypted message:"^decrypted)
