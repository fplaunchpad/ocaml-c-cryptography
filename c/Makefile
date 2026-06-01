CC = gcc
CFLAGS = -O2 -Wall -Wextra

TARGET = xor
SRC = xor_cipher.c

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) $(SRC) -o $(TARGET)

clean:
	rm -f $(TARGET)

run: $(TARGET)
	./$(TARGET)

.PHONY: all clean run
