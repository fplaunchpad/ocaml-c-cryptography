#include<stdio.h>
#include<string.h>
//Your C encrypted output may sometimes print weird symbols or stop early because XOR can produce '\0' or non-printable bytes.
int main(){
    char str[100], key[100];
    printf("Enter the string to encrypt: ");
    fgets(str, sizeof(str), stdin);
    printf("Enter the key: ");
    fgets(key, sizeof(key), stdin);

    str[strcspn(str, "\n")] = '\0';
    key[strcspn(key, "\n")] = '\0';

    int str_len = strlen(str);
    int key_len = strlen(key);
    char encrypted[100], decrypted[100];

    for (int i = 0; i < str_len; i++) {
        encrypted[i] = str[i] ^ key[i % key_len];
    }
    encrypted[str_len] = '\0';

    printf("Encrypted string: %s\n", encrypted);

    // Decrypt the string using XOR cipher
    for (int i = 0; i < str_len; i++) {
        decrypted[i] = encrypted[i] ^ key[i % key_len];
    }
    decrypted[str_len] = '\0';

    printf("Decrypted string: %s\n", decrypted);

    return 0;
}