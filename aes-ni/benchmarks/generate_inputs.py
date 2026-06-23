import os

base_text = (
    "AdvancedEncryptionStandardBenchmarkData123\n"
)

def generate_file(filename, size_mb):
    target_size = size_mb * 1024 * 1024

    with open(filename, "w") as f:
        written = 0

        while written < target_size:
            f.write(base_text)
            written += len(base_text)

    actual_size = os.path.getsize(filename)

    print(
        f"{filename}: "
        f"{actual_size / (1024 * 1024):.2f} MB"
    )

generate_file("input_1mb.txt", 1)
generate_file("input_10mb.txt", 10)
generate_file("input_30mb.txt", 30)
generate_file("input_50mb.txt", 50)
generate_file("input_75mb.txt", 75)
generate_file("input_100mb.txt", 100)