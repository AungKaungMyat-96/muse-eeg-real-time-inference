# -----------------------------------------------------------------------------
# AV7K325 smoke-test constraints for top_cnn_av7k325
# Device: xc7k325tffg900-2
# -----------------------------------------------------------------------------

# Differential 200 MHz system clock
set_property PACKAGE_PIN AE10 [get_ports sys_clk_p]
set_property PACKAGE_PIN AF10 [get_ports sys_clk_n]
set_property IOSTANDARD LVDS [get_ports sys_clk_p]
set_property IOSTANDARD LVDS [get_ports sys_clk_n]
create_clock -period 5.000 -name sys_clk [get_ports sys_clk_p]

# User KEY1 (active-low when pressed)
set_property PACKAGE_PIN AD24 [get_ports key1]
set_property IOSTANDARD LVCMOS33 [get_ports key1]

# User LEDs (active-low on AV7K325 board)
set_property PACKAGE_PIN Y28 [get_ports led1]
set_property PACKAGE_PIN AA28 [get_ports led2]
set_property IOSTANDARD LVCMOS33 [get_ports led1]
set_property IOSTANDARD LVCMOS33 [get_ports led2]
