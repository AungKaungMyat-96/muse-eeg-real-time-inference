# -----------------------------------------------------------------------------
# inference_top_av7k325 constraints
# Device: xc7k325tffg900-2 (AV7K325)
# -----------------------------------------------------------------------------

# Optional configuration voltage properties (enable if board flow requires these)
# set_property CFGBVS VCCO [current_design]
# set_property CONFIG_VOLTAGE 3.3 [current_design]

# Differential 200 MHz system clock
set_property PACKAGE_PIN AE10 [get_ports sys_clk_p]
set_property PACKAGE_PIN AF10 [get_ports sys_clk_n]
set_property IOSTANDARD LVDS [get_ports sys_clk_p]
set_property IOSTANDARD LVDS [get_ports sys_clk_n]
create_clock -period 5.000 -name sys_clk [get_ports sys_clk_p]

# User KEY1 (active-low when pressed, high when released)
set_property PACKAGE_PIN AD24 [get_ports key1]
set_property IOSTANDARD LVCMOS33 [get_ports key1]

# User LEDs (active-low on AV7K325 board)
set_property PACKAGE_PIN Y28 [get_ports led_done]
set_property PACKAGE_PIN AA28 [get_ports led_class]
set_property IOSTANDARD LVCMOS33 [get_ports led_done]
set_property IOSTANDARD LVCMOS33 [get_ports led_class]
