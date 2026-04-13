import sys
import serial
import numpy as np
import pyqtgraph as pg
from pyqtgraph.Qt import QtWidgets, QtCore
import time

SERIAL_PORT = 'COM3'
BAUD_RATE = 115200
UPDATE_INTERVAL_MS = 10

# SINGLE CHANNEL INPUT (TRANSFORMED SIGNAL)

try:
    ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=0.1)
    use_serial = True
    print(f"Using serial port {SERIAL_PORT}")
except:
    use_serial = False
    print("Using dummy mode")

# ---------------- PLOT SETUP ----------------
app = QtWidgets.QApplication([])
win = pg.GraphicsLayoutWidget(title="Live Single Channel Signal")
plot = win.addPlot(title="Transformed Signal")

plot.setLabel('bottom', "Time", units='s')
plot.setLabel('left', "ADC Value (12-bit)")
plot.setYRange(0, 4095)

curve = plot.plot(pen='y', name="Signal")

win.show()

# ---------------- BUFFERS ----------------
signal_history = []
time_history = []

serial_buffer = bytearray()

t0 = time.time()
MAX_POINTS = 5000

# ---------------- UPDATE LOOP ----------------
def update():
    global signal_history, time_history, serial_buffer

    t_rel = time.time() - t0
    new_samples = []

    if use_serial:
        data = ser.read(ser.in_waiting or 1)
        serial_buffer.extend(data)

        while True:
            start_idx = serial_buffer.find(b'\xAA')

            if start_idx == -1:
                serial_buffer.clear()
                break

            # need full frame: AA + 2 data bytes + FF = 4 bytes
            if len(serial_buffer) < start_idx + 4:
                break

            # check end byte
            if serial_buffer[start_idx + 3] == 0xFF:

                frame = serial_buffer[start_idx:start_idx + 4]

                # ---------------- 12-bit reconstruction ----------------
                msb_nibble = frame[1] & 0x0F
                lsb_byte = frame[2]

                value = (msb_nibble << 8) | lsb_byte

                new_samples.append(value)

                # remove processed frame
                serial_buffer = serial_buffer[start_idx + 4:]

            else:
                serial_buffer = serial_buffer[start_idx + 1:]

    else:
        # dummy signal
        t = np.linspace(0, 2*np.pi, 20)
        new_samples = (2048 + 1000*np.sin(t)).tolist()

    # ---------------- UPDATE PLOT ----------------
    if new_samples:
        n = len(new_samples)

        signal_history.extend(new_samples)

        dt = 1 / 1000
        times = [t_rel + i * dt for i in range(n)]
        time_history.extend(times)

        if len(time_history) > MAX_POINTS:
            signal_history = signal_history[-MAX_POINTS:]
            time_history = time_history[-MAX_POINTS:]

        curve.setData(time_history, signal_history)

# ---------------- TIMER ----------------
timer = QtCore.QTimer()
timer.timeout.connect(update)
timer.start(UPDATE_INTERVAL_MS)

sys.exit(app.exec())