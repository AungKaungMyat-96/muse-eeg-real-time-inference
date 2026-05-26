# -----------------------------------------------------------------------------
# run_milestone7a_sim.tcl
# Purpose:
#   Run Milestone 7A behavioral simulation for ReLU3 + GAP standalone.
# Usage:
#   Open project_1 in Vivado, then in Tcl console:
#   source D:/Users/Lenovo/project_1/muse_cnn_sources/run_milestone7a_sim.tcl
# -----------------------------------------------------------------------------

puts "INFO: Starting Milestone 7A ReLU3 + GAP standalone simulation flow..."

set_property top relu3_gap_tb [get_filesets sim_1]
update_compile_order -fileset sim_1

if {[string equal [current_sim] ""]} {
    launch_simulation
} else {
    relaunch_sim
}

# Avoid huge testbench arrays in waveform.
catch {remove_wave [get_waves *input_mem*]}
catch {remove_wave [get_waves *relu_expected_mem*]}
catch {remove_wave [get_waves *gap_expected_mem*]}
catch {remove_wave [get_waves *sum_mem*]}

# Keep useful signals only.
catch {add_wave /relu3_gap_tb/clk}
catch {add_wave /relu3_gap_tb/rst_n}
catch {add_wave /relu3_gap_tb/in_valid}
catch {add_wave /relu3_gap_tb/in_data}
catch {add_wave /relu3_gap_tb/in_t_idx}
catch {add_wave /relu3_gap_tb/in_f_idx}

catch {add_wave /relu3_gap_tb/relu_out_valid}
catch {add_wave /relu3_gap_tb/relu_out_data}
catch {add_wave /relu3_gap_tb/relu_out_t_idx}
catch {add_wave /relu3_gap_tb/relu_out_f_idx}

catch {add_wave /relu3_gap_tb/gap_out_valid}
catch {add_wave /relu3_gap_tb/gap_out_data}
catch {add_wave /relu3_gap_tb/gap_out_f_idx}

catch {add_wave /relu3_gap_tb/relu3_compared}
catch {add_wave /relu3_gap_tb/relu3_mismatches}
catch {add_wave /relu3_gap_tb/gap_compared}
catch {add_wave /relu3_gap_tb/gap_mismatches}

puts "INFO: Running simulation for 30 ms..."
run 30 ms

puts "INFO: Simulation run command completed."
puts "CHECK TCL CONSOLE FOR:"
puts "  - Loaded counts OK: input=48000 relu_expected=48000 gap_expected=64"
puts "  - PASS: relu3_compared=48000 relu3_mismatches=0 gap_compared=64 gap_mismatches=0"
puts "If PASS line is missing, search for FAIL, FIRST_RELU3_MISMATCH, or FIRST_GAP_MISMATCH."
