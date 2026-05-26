# ============================================================================
# top_cnn_constraints_template.xdc
# Target board: ALINX AV7K325 (Kintex-7 xc7k325tffg900-2)
# Purpose:
#   Constraint preparation template for top module: top_cnn
#
# IMPORTANT:
# - Use only verified PACKAGE_PIN and IOSTANDARD values from the official
#   AV7K325 user manual/schematic before uncommenting constraints.
# - Do not program hardware with guessed pins or guessed voltage standards.
# - This file is intentionally commented as a safe pre-assignment template.
# ============================================================================

# ----------------------------------------------------------------------------
# Clock constraint template
# ----------------------------------------------------------------------------
# TODO: Confirm whether top_cnn.clk is connected to a single-ended board clock
#       or derived from differential SYS_CLK_P/SYS_CLK_N through clocking logic.
# TODO: Confirm actual clock frequency used by this top-level port.
#
# Example (single-ended clock on top-level clk):
# set_property PACKAGE_PIN <CLK_PIN> [get_ports clk]
# set_property IOSTANDARD <CLK_IOSTANDARD> [get_ports clk]
# create_clock -name sys_clk -period <PERIOD_NS> [get_ports clk]

# ----------------------------------------------------------------------------
# Reset input (active-low)
# ----------------------------------------------------------------------------
# TODO: Map rst_n to a verified push-button or external reset source.
# set_property PACKAGE_PIN <RST_PIN> [get_ports rst_n]
# set_property IOSTANDARD <RST_IOSTANDARD> [get_ports rst_n]

# ----------------------------------------------------------------------------
# Input valid control
# ----------------------------------------------------------------------------
# TODO: Map in_valid to a verified key/switch/header input pin.
# set_property PACKAGE_PIN <IN_VALID_PIN> [get_ports in_valid]
# set_property IOSTANDARD <IN_VALID_IOSTANDARD> [get_ports in_valid]

# ----------------------------------------------------------------------------
# Input data bus: in_data[7:0]
# ----------------------------------------------------------------------------
# TODO: Map each bit to verified switch/header pins.
# set_property PACKAGE_PIN <IN_DATA0_PIN> [get_ports {in_data[0]}]
# set_property PACKAGE_PIN <IN_DATA1_PIN> [get_ports {in_data[1]}]
# set_property PACKAGE_PIN <IN_DATA2_PIN> [get_ports {in_data[2]}]
# set_property PACKAGE_PIN <IN_DATA3_PIN> [get_ports {in_data[3]}]
# set_property PACKAGE_PIN <IN_DATA4_PIN> [get_ports {in_data[4]}]
# set_property PACKAGE_PIN <IN_DATA5_PIN> [get_ports {in_data[5]}]
# set_property PACKAGE_PIN <IN_DATA6_PIN> [get_ports {in_data[6]}]
# set_property PACKAGE_PIN <IN_DATA7_PIN> [get_ports {in_data[7]}]
#
# set_property IOSTANDARD <IN_DATA_IOSTANDARD> [get_ports {in_data[*]}]

# ----------------------------------------------------------------------------
# Output valid flag
# ----------------------------------------------------------------------------
# TODO: Map out_valid to a verified LED/header output pin.
# set_property PACKAGE_PIN <OUT_VALID_PIN> [get_ports out_valid]
# set_property IOSTANDARD <OUT_VALID_IOSTANDARD> [get_ports out_valid]

# ----------------------------------------------------------------------------
# Output data bus: out_data[7:0]
# ----------------------------------------------------------------------------
# TODO: Map each bit to verified LEDs/header pins.
# set_property PACKAGE_PIN <OUT_DATA0_PIN> [get_ports {out_data[0]}]
# set_property PACKAGE_PIN <OUT_DATA1_PIN> [get_ports {out_data[1]}]
# set_property PACKAGE_PIN <OUT_DATA2_PIN> [get_ports {out_data[2]}]
# set_property PACKAGE_PIN <OUT_DATA3_PIN> [get_ports {out_data[3]}]
# set_property PACKAGE_PIN <OUT_DATA4_PIN> [get_ports {out_data[4]}]
# set_property PACKAGE_PIN <OUT_DATA5_PIN> [get_ports {out_data[5]}]
# set_property PACKAGE_PIN <OUT_DATA6_PIN> [get_ports {out_data[6]}]
# set_property PACKAGE_PIN <OUT_DATA7_PIN> [get_ports {out_data[7]}]
#
# set_property IOSTANDARD <OUT_DATA_IOSTANDARD> [get_ports {out_data[*]}]

# ----------------------------------------------------------------------------
# Optional debugging properties (enable after pin mapping is finalized)
# ----------------------------------------------------------------------------
# TODO: Add optional SLEW/DRIVE/PULLUP/PULLDOWN constraints if required by
#       board electrical design and verified bank voltage.
