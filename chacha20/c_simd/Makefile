CC      = gcc
CFLAGS  = -O3 -march=native -Wall -Wextra

TARGET  = benchmark_chacha20_simd
SRCS    = chacha20_simd.c benchmark_chacha20_simd.c

all: $(TARGET)

$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) -o $@ $^

clean:
	rm -f $(TARGET)
