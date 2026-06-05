import os

base_dir = os.path.dirname(os.path.abspath(__file__))

base_text = (
    "CryptographyAndFunctionalProgrammingResearch123\n"
)

def generate_file(filename, size_mb):
    path = os.path.join(base_dir, filename)

    target_size = size_mb * 1024 * 1024

    with open(path, "w") as f:
        written = 0

        while written < target_size:
            f.write(base_text)
            written += len(base_text)

    actual_size = os.path.getsize(path)

    print(f"{filename}: {actual_size / (1024 * 1024):.2f} MB")

generate_file("input_1mb.txt", 1)
generate_file("input_10mb.txt", 10)
generate_file("input_100mb.txt", 100)

with open(os.path.join(base_dir, "key.txt"), "w") as f:
    f.write("securekeyforxorbenchmark123456")