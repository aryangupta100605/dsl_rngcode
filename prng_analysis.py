import numpy as np
import matplotlib.pyplot as plt

# Read frames from uart_capture.txt (each line: AA xx xx xx xx FF)
frames = []
with open('uart_capture.txt', 'r') as f:
    for line in f:
        parts = line.strip().split()
        if len(parts) == 6 and parts[0] == 'AA' and parts[-1] == 'FF':
            # Convert middle 4 bytes to a 32-bit integer
            value = int(''.join(parts[1:5]), 16)
            frames.append(value)

if not frames:
    print("No valid frames found.")
    exit(1)

frames = np.array(frames)

# Histogram
plt.figure(figsize=(10,4))
plt.subplot(1,2,1)
plt.hist(frames, bins=50, color='skyblue', edgecolor='black')
plt.title('Histogram of pRNG values')
plt.xlabel('pRNG Value')
plt.ylabel('Count')


plt.tight_layout()
plt.show()

# Average value
print(f"Average pRNG value: {np.mean(frames):.2f}")
