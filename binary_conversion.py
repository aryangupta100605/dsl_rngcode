# Convert UART hex dump to binary, removing 0xFF and 0xAA bytes

input_file = "uart_capture.txt"
output_file = "output.bin"

frame_count = 0

with open(input_file, "r") as fin, open(output_file, "wb") as fout:
    for line in fin:
        # Split line into hex byte strings
        byte_strs = line.strip().split()
        # Exclude first and last if they are 0xAA or 0xFF
        if byte_strs and byte_strs[0] in ("AA", "FF"):
            byte_strs = byte_strs[1:]
        if byte_strs and byte_strs[-1] in ("AA", "FF"):
            byte_strs = byte_strs[:-1]
        for byte_str in byte_strs:
            byte = int(byte_str, 16)
            fout.write(bytes([byte]))
            frame_count += 1

print(f"Conversion complete. Output written to output.bin. {frame_count} frames converted.")