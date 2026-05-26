# -----------------------------------------------------------------------------
# run_milestone8a_sim.tcl
# Purpose:
#   Run Milestone 8A integrated classifier behavioral simulation:
#   GAP -> Dense1 -> ReLU -> Dense2.
# Usage:
#   Open project_1 in Vivado, then in Tcl console:
#   source D:/Users/Lenovo/project_1/muse_cnn_sources/run_milestone8a_sim.tcl
# -----------------------------------------------------------------------------

puts "INFO: Starting Milestone 8A integrated classifier simulation flow..."

set_property top gap_dense1_relu_dense2_tb [get_filesets sim_1]
update_compile_order -fileset sim_1

if {[string equal [current_sim] ""]} {
    launch_simulation
} else {
    relaunch_sim
}

# Avoid huge testbench arrays in waveform.
catch {remove_wave [get_waves *input_mem*]}
catch {remove_wave [get_waves *expected_mem*]}
catch {remove_wave [get_waves *weight_mem*]}
catch {remove_wave [get_waves *bias_mem*]}

# Keep useful stage and progress signals.
catch {add_wave /gap_dense1_relu_dense2_tb/clk}
catch {add_wave /gap_dense1_relu_dense2_tb/rst_n}
catch {add_wave /gap_dense1_relu_dense2_tb/in_valid}
catch {add_wave /gap_dense1_relu_dense2_tb/in_data}

catch {add_wave /gap_dense1_relu_dense2_tb/dense1_out_valid}
catch {add_wave /gap_dense1_relu_dense2_tb/dense1_out_data}
catch {add_wave /gap_dense1_relu_dense2_tb/dense1_out_o_idx}

catch {add_wave /gap_dense1_relu_dense2_tb/relu_out_valid}
catch {add_wave /gap_dense1_relu_dense2_tb/relu_out_data}
catch {add_wave /gap_dense1_relu_dense2_tb/relu_out_f_idx}

catch {add_wave /gap_dense1_relu_dense2_tb/dense2_out_valid}
catch {add_wave /gap_dense1_relu_dense2_tb/dense2_out_data}
catch {add_wave /gap_dense1_relu_dense2_tb/dense2_out_c_idx}

catch {add_wave /gap_dense1_relu_dense2_tb/dense1_count}
catch {add_wave /gap_dense1_relu_dense2_tb/relu_count}
catch {add_wave /gap_dense1_relu_dense2_tb/dense2_count}
catch {add_wave /gap_dense1_relu_dense2_tb/classifier_compared}
catch {add_wave /gap_dense1_relu_dense2_tb/mismatch_count}

puts "INFO: Running simulation for 20 ms..."
run 20 ms

puts "INFO: Simulation run command completed."
puts "CHECK TCL CONSOLE FOR:"
puts "  - Loaded counts OK: input=64 expected=2"
puts "  - PASS: classifier_compared=2 mismatches=0"
puts "If PASS line is missing, search for FAIL or FIRST_CLASSIFIER_MISMATCH."
