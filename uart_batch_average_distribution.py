import numpy as np
import matplotlib.pyplot as plt

# Read frames from uart_capture.txt (each line: AA xx xx xx xx FF)
def read_frames(filename):
    frames = []
    with open(filename, 'r') as f:
        for line in f:
            parts = line.strip().split()
            if len(parts) == 6 and parts[0] == 'AA' and parts[-1] == 'FF':
                value = int(''.join(parts[1:5]), 16)
                frames.append(value)
    return np.array(frames)

frames = read_frames('uart_capture.txt')
if len(frames) < 50:
    print("Not enough frames for binning.")
    exit(1)

bin_size = 50
num_bins = len(frames) // bin_size
batch_averages = [np.mean(frames[i*bin_size:(i+1)*bin_size]) for i in range(num_bins)]

plt.figure(figsize=(8,5))
plt.hist(batch_averages, bins=50, color='skyblue', edgecolor='black')
plt.title('Distribution of Averages of 50 Frames')
plt.xlabel('Average Value (per 50 frames)')
plt.ylabel('Count')
plt.tight_layout()
plt.show()

# Print a simple frequency table (rounded to nearest int)
from collections import Counter
rounded_averages = [int(round(x)) for x in batch_averages]
counts = Counter(rounded_averages)
print("Value : Count")
for value, count in sorted(counts.items()):
    print(f"{value} : {count}")
