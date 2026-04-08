import sys
import serial
import numpy as np
import pyqtgraph as pg
from pyqtgraph.Qt import QtWidgets, QtCore
import time

SERIAL_PORT = 'COM3'
BAUD_RATE = 115200
UPDATE_INTERVAL_MS = 10

# Try opening serial
try:
    ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=0.1)
    use_serial = True
    print(f"Using serial port {SERIAL_PORT}")
except:
    use_serial = False
    print("Using dummy mode")

# PyQtGraph setup
app = QtWidgets.QApplication([])
win = pg.GraphicsLayoutWidget(title="Live ADC Signal - 2 Channels")
plot = win.addPlot(title="Piezo Signals")
plot.setLabel('bottom', "Time", units='s')
plot.setLabel('left', "ADC Value", units='counts')
curve_ch0 = plot.plot(pen='y', name="CH0")
curve_ch1 = plot.plot(pen='r', name="CH1")
win.show()

# Buffers for recording
adc_history_ch0 = []
adc_history_ch1 = []
time_history = []

# Start the time
t0 = time.time()

# Serial buffer
serial_buffer = bytearray()

def update():
    global adc_history_ch0, adc_history_ch1, time_history, serial_buffer

    current_time = time.time()
    t_rel = current_time - t0  # time since start

    new_samples_ch0 = []
    new_samples_ch1 = []

    if use_serial:
        # read all available bytes
        data = ser.read(ser.in_waiting or 1)
        serial_buffer.extend(data)

        # Each "sample pair" = 4 bytes (CH0 high, CH0 low, CH1 high, CH1 low)
        num_samples = len(serial_buffer) // 4
        if num_samples > 0:
            for i in range(num_samples):
                b0 = serial_buffer[i*4 + 0]
                b1 = serial_buffer[i*4 + 1]
                b2 = serial_buffer[i*4 + 2]
                b3 = serial_buffer[i*4 + 3]

                sample_ch0 = (b0 << 8) | b1
                sample_ch1 = (b2 << 8) | b3

                new_samples_ch0.append(sample_ch0)
                new_samples_ch1.append(sample_ch1)

            # remove processed bytes
            serial_buffer = serial_buffer[num_samples*4:]
    else:
        # dummy waveform
        new_samples_ch0 = (2048 + 1000*np.sin(np.linspace(0, 2*np.pi, 10))).tolist()
        new_samples_ch1 = (2048 + 500*np.cos(np.linspace(0, 2*np.pi, 10))).tolist()

    if new_samples_ch0:
        n = len(new_samples_ch0)
        # Append new samples
        adc_history_ch0.extend(new_samples_ch0)
        adc_history_ch1.extend(new_samples_ch1)

        # Append corresponding timestamps, spaced evenly
        dt = 1/1000  # assume ~1 ms per sample; adjust if known
        times = [t_rel + i*dt for i in range(n)]
        time_history.extend(times)

        # Update plot
        curve_ch0.setData(time_history, adc_history_ch0)
        curve_ch1.setData(time_history, adc_history_ch1)
        plot.enableAutoRange('y', True)  # auto-scale y-axis

# Timer
timer = QtCore.QTimer()
timer.timeout.connect(update)
timer.start(UPDATE_INTERVAL_MS)

sys.exit(app.exec())