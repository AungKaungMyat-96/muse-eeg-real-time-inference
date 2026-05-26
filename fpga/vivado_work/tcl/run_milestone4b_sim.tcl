# -----------------------------------------------------------------------------
# run_milestone4b_sim.tcl
# Purpose:
#   Run Milestone 4B behavioral simulation for
#   Conv1 -> ReLU1 -> MaxPool1 -> Conv2 integrated pipeline.
# Usage:
#   Open project_1 in Vivado, then in Tcl console:
#   source D:/Users/Lenovo/project_1/muse_cnn_sources/run_milestone4b_sim.tcl
# -----------------------------------------------------------------------------

puts "INFO: Starting Milestone 4B integrated Conv1->ReLU->MaxPool->Conv2 simulation flow..."

set_property top conv1_relu_pool_conv2_tb [get_filesets sim_1]
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
catch {remove_wave [get_waves *hold_data*]}

# Keep useful signals only.
catch {add_wave /conv1_relu_pool_conv2_tb/clk}
catch {add_wave /conv1_relu_pool_conv2_tb/rst_n}
catch {add_wave /conv1_relu_pool_conv2_tb/in_valid}
catch {add_wave /conv1_relu_pool_conv2_tb/in_data}

catch {add_wave /conv1_relu_pool_conv2_tb/conv1_out_valid}
catch {add_wave /conv1_relu_pool_conv2_tb/conv1_out_data}

catch {add_wave /conv1_relu_pool_conv2_tb/relu_out_valid}
catch {add_wave /conv1_relu_pool_conv2_tb/relu_out_data}

catch {add_wave /conv1_relu_pool_conv2_tb/pool_out_valid}
catch {add_wave /conv1_relu_pool_conv2_tb/pool_out_data}

catch {add_wave /conv1_relu_pool_conv2_tb/conv2_out_valid}
catch {add_wave /conv1_relu_pool_conv2_tb/conv2_out_data}
catch {add_wave /conv1_relu_pool_conv2_tb/conv2_out_t_idx}
catch {add_wave /conv1_relu_pool_conv2_tb/conv2_out_f_idx}

catch {add_wave /conv1_relu_pool_conv2_tb/integrated_conv2_compared}
catch {add_wave /conv1_relu_pool_conv2_tb/mismatch_count}
catch {add_wave /conv1_relu_pool_conv2_tb/relu_count}
catch {add_wave /conv1_relu_pool_conv2_tb/pool_count}

puts "INFO: Running simulation for 180 ms..."
run 180 ms

puts "INFO: Simulation run command completed."
puts "CHECK TCL CONSOLE FOR:"
puts "  - Loaded counts OK: input=6000 expected=48000"
puts "  - PASS: integrated_conv2_compared=48000 mismatches=0"
puts "If PASS line is missing, search for FAIL or FIRST_INTEGRATED_CONV2_MISMATCH."
