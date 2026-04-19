import serial
import time

SERIAL_PORT = 'COM4'      # Change to your serial port
BAUD_RATE = 115200
OUTPUT_FILE = 'uart_capture.txt'
CAPTURE_SECONDS = 11000

# --- RAW BYTE DEBUGGING ---
# This will print every received byte as hex to the console for debugging.
ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
end_time = time.time() + CAPTURE_SECONDS


raw_bytes = []
while time.time() < end_time:
    b = ser.read(1)
    if b:
        raw_bytes.append(b[0])

ser.close()
print(f"Captured {len(raw_bytes)} bytes.")

# --- FRAME EXTRACTION ---
frames = []
frame = []
for byte in raw_bytes:
    if not frame:
        if byte == 0xAA:
            frame = [byte]
    elif len(frame) < 6:
        frame.append(byte)
        if len(frame) == 6:
            if frame[-1] == 0xFF:
                frames.append(frame)
            frame = []

with open(OUTPUT_FILE, 'w') as f:
    for frame in frames:
        f.write(' '.join(f'{b:02X}' for b in frame) + '\n')

print(f"\nExtracted {len(frames)} frames. Saved to {OUTPUT_FILE}")