CC = gcc
CFLAGS = -O2 -Wall -Wextra

XOR_TARGET = xor
AES_TARGET = aes

all: $(XOR_TARGET) $(AES_TARGET)

$(XOR_TARGET): xor_cipher.c
	$(CC) $(CFLAGS) xor_cipher.c -o $(XOR_TARGET)

$(AES_TARGET): aes.c
	$(CC) $(CFLAGS) aes.c -o $(AES_TARGET)

clean:
	rm -f $(XOR_TARGET) $(AES_TARGET)

run-xor: $(XOR_TARGET)
	./$(XOR_TARGET)

run-aes: $(AES_TARGET)
	./$(AES_TARGET)

.PHONY: all clean run-xor run-aes