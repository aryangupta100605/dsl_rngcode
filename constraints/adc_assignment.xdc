# =========================
# 1. Clock & Buttons (Bank 0, 1.8V)
# =========================
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets sysclk_IBUF]
set_property PACKAGE_PIN L17 [get_ports {sysclk}]
set_property IOSTANDARD LVCMOS33 [get_ports {sysclk}]
create_clock -add -name sys_clk_pin -period 83.33 -waveform {0 41.66} [get_ports {sysclk}]

set_property -dict { PACKAGE_PIN A17   IOSTANDARD LVCMOS33 } [get_ports { led }]; #IO_L12N_T1_MRCC_16 Sch=led[1]
set_property PACKAGE_PIN A18 [get_ports {btn[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn[0]}]

set_property PACKAGE_PIN B18 [get_ports {btn[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn[1]}]

# =========================
# 2. 7-Segment Display Segments (Bank 15, 3.3V)
# =========================
set_property PACKAGE_PIN B15 [get_ports {seg[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[7]}]

set_property PACKAGE_PIN K3  [get_ports {seg[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[6]}]

set_property PACKAGE_PIN A14 [get_ports {seg[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[5]}]

set_property PACKAGE_PIN K2  [get_ports {seg[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[4]}]

set_property PACKAGE_PIN J3  [get_ports {seg[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[3]}]

set_property PACKAGE_PIN H1  [get_ports {seg[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[2]}]

set_property PACKAGE_PIN A16 [get_ports {seg[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[1]}]

set_property PACKAGE_PIN J1  [get_ports {seg[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[0]}]

# =========================
# 3. 7-Segment Hex Digits (Bank 14, 3.3V)
# =========================
set_property PACKAGE_PIN L2  [get_ports {hex[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {hex[3]}]

set_property PACKAGE_PIN L1  [get_ports {hex[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {hex[2]}]

set_property PACKAGE_PIN A15 [get_ports {hex[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {hex[1]}]

set_property PACKAGE_PIN C15 [get_ports {hex[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {hex[0]}]

# =========================
# 4. Pmod Header JA - MCP3202 (Bank 34, 3.3V)
# =========================
set_property PACKAGE_PIN H17 [get_ports {adc_din}]
set_property IOSTANDARD LVCMOS33 [get_ports {adc_din}]

set_property PACKAGE_PIN H19 [get_ports {adc_csn}]
set_property IOSTANDARD LVCMOS33 [get_ports {adc_csn}]

set_property PACKAGE_PIN J19 [get_ports {adc_clk}]
set_property IOSTANDARD LVCMOS33 [get_ports {adc_clk}]

set_property PACKAGE_PIN K18 [get_ports {adc_dout}]
set_property IOSTANDARD LVCMOS33 [get_ports {adc_dout}]

# =========================
# 5. UART (Bank 15, 3.3V)
# =========================
set_property PACKAGE_PIN J18 [get_ports {uart_rxd_out}]
set_property IOSTANDARD LVCMOS33 [get_ports {uart_rxd_out}]

set_property PACKAGE_PIN J17 [get_ports {uart_txd_in}]
set_property IOSTANDARD LVCMOS33 [get_ports {uart_txd_in}]