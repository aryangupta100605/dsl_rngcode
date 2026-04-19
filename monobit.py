# Monobit test: count and percentage of 0s and 1s in output.bin

input_file = "output.bin"

count_ones = 0
count_zeros = 0

with open(input_file, "rb") as f:
    data = f.read()
    for byte in data:
        for i in range(8):
            if (byte >> i) & 1:
                count_ones += 1
            else:
                count_zeros += 1

total_bits = count_ones + count_zeros
percent_ones = (count_ones / total_bits) * 100 if total_bits else 0
percent_zeros = (count_zeros / total_bits) * 100 if total_bits else 0

print(f"Number of 1s: {count_ones} ({percent_ones:.4f}%)")
print(f"Number of 0s: {count_zeros} ({percent_zeros:.4f}%)")