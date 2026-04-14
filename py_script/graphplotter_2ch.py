import sys
import serial
import numpy as np
import pyqtgraph as pg
from pyqtgraph.Qt import QtWidgets, QtCore
import time

SERIAL_PORT = 'COM3'
BAUD_RATE = 115200
UPDATE_INTERVAL_MS = 10


# TWO CHANNEL INPUT
try:
    ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=0.1)
    use_serial = True
    print(f"Using serial port {SERIAL_PORT}")
except:
    use_serial = False
    print("Using dummy mode")

# ---------------- PLOT ----------------
app = QtWidgets.QApplication([])
win = pg.GraphicsLayoutWidget(title="Live ADC Signal - 2 Channels")
plot = win.addPlot(title="Channel Signals")

plot.setLabel('bottom', "Time", units='s')
plot.setLabel('left', "ADC Value (12-bit)")
plot.setYRange(0, 4095)

# Ch0: Yellow
# Ch1: Red
curve_ch0 = plot.plot(pen='y', name="CH0")
curve_ch1 = plot.plot(pen='r', name="CH1")

win.show()

# ---------------- BUFFERS ----------------
adc_history_ch0 = []
adc_history_ch1 = []
time_history = []

serial_buffer = bytearray()

t0 = time.time()
MAX_POINTS = 5000

# ---------------- UPDATE LOOP ----------------
def update():
    global adc_history_ch0, adc_history_ch1, time_history, serial_buffer

    t_rel = time.time() - t0

    new_ch0 = []
    new_ch1 = []

    if use_serial:
        data = ser.read(ser.in_waiting or 1)
        serial_buffer.extend(data)

        # ---------------- FRAME PARSER ----------------
        while True:
            start_idx = serial_buffer.find(b'\xAA')

            if start_idx == -1:
                serial_buffer.clear()
                break
            # Starting byte: AA, Ending byte: FF
            
            # need full frame: AA + 4 data bytes + FF = 6 bytes
            if len(serial_buffer) < start_idx + 6:
                break

            # check end byte
            if serial_buffer[start_idx + 5] == 0xFF:

                frame = serial_buffer[start_idx:start_idx + 6]

                # ---------------- EXTRACT DATA ----------------
                ch0 = (frame[1] << 8) | frame[2]
                ch1 = (frame[3] << 8) | frame[4]

                new_ch0.append(ch0)
                new_ch1.append(ch1)

                # remove processed frame
                serial_buffer = serial_buffer[start_idx + 6:]

            else:
                serial_buffer = serial_buffer[start_idx + 1:]

    else:
        # dummy test
        t = np.linspace(0, 2*np.pi, 20)
        new_ch0 = (2048 + 1000*np.sin(t)).tolist()
        new_ch1 = (2048 + 500*np.cos(t)).tolist()

    # ---------------- UPDATE PLOT ----------------
    if new_ch0:
        n = len(new_ch0)

        adc_history_ch0.extend(new_ch0)
        adc_history_ch1.extend(new_ch1)

        dt = 1 / 1000
        times = [t_rel + i * dt for i in range(n)]
        time_history.extend(times)

        # limit memory
        if len(time_history) > MAX_POINTS:
            adc_history_ch0 = adc_history_ch0[-MAX_POINTS:]
            adc_history_ch1 = adc_history_ch1[-MAX_POINTS:]
            time_history = time_history[-MAX_POINTS:]

        curve_ch0.setData(time_history, adc_history_ch0)
        curve_ch1.setData(time_history, adc_history_ch1)

# ---------------- TIMER ----------------
timer = QtCore.QTimer()
timer.timeout.connect(update)
timer.start(UPDATE_INTERVAL_MS)

sys.exit(app.exec())