# -----------------------------------------------------------------------------
# run_milestone6_sim.tcl
# Purpose:
#   Run Milestone 6 behavioral simulation for integrated
#   Conv1 -> ReLU1 -> Pool1 -> Conv2 -> Pool2 -> Conv3.
# Usage:
#   Open project_1 in Vivado, then in Tcl console:
#   source D:/Users/Lenovo/project_1/muse_cnn_sources/run_milestone6_sim.tcl
# -----------------------------------------------------------------------------

puts "INFO: Starting Milestone 6 integrated Conv1->ReLU1->Pool1->Conv2->Pool2->Conv3 simulation flow..."

set_property top conv1_pool1_conv2_pool2_conv3_tb [get_filesets sim_1]
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

# Keep useful stage and progress signals.
catch {add_wave /conv1_pool1_conv2_pool2_conv3_tb/clk}
catch {add_wave /conv1_pool1_conv2_pool2_conv3_tb/rst_n}
catch {add_wave /conv1_pool1_conv2_pool2_conv3_tb/in_valid}
catch {add_wave /conv1_pool1_conv2_pool2_conv3_tb/in_data}

catch {add_wave /conv1_pool1_conv2_pool2_conv3_tb/conv1_out_valid}
catch {add_wave /conv1_pool1_conv2_pool2_conv3_tb/conv1_out_data}
catch {add_wave /conv1_pool1_conv2_pool2_conv3_tb/relu1_out_valid}
catch {add_wave /conv1_pool1_conv2_pool2_conv3_tb/relu1_out_data}
catch {add_wave /conv1_pool1_conv2_pool2_conv3_tb/pool1_out_valid}
catch {add_wave /conv1_pool1_conv2_pool2_conv3_tb/pool1_out_data}
catch {add_wave /conv1_pool1_conv2_pool2_conv3_tb/conv2_out_valid}
catch {add_wave /conv1_pool1_conv2_pool2_conv3_tb/conv2_out_data}
catch {add_wave /conv1_pool1_conv2_pool2_conv3_tb/pool2_out_valid}
catch {add_wave /conv1_pool1_conv2_pool2_conv3_tb/pool2_out_data}
catch {add_wave /conv1_pool1_conv2_pool2_conv3_tb/conv3_out_valid}
catch {add_wave /conv1_pool1_conv2_pool2_conv3_tb/conv3_out_data}
catch {add_wave /conv1_pool1_conv2_pool2_conv3_tb/conv3_out_t_idx}
catch {add_wave /conv1_pool1_conv2_pool2_conv3_tb/conv3_out_f_idx}

catch {add_wave /conv1_pool1_conv2_pool2_conv3_tb/conv1_count}
catch {add_wave /conv1_pool1_conv2_pool2_conv3_tb/relu1_count}
catch {add_wave /conv1_pool1_conv2_pool2_conv3_tb/pool1_count}
catch {add_wave /conv1_pool1_conv2_pool2_conv3_tb/conv2_count}
catch {add_wave /conv1_pool1_conv2_pool2_conv3_tb/pool2_count}
catch {add_wave /conv1_pool1_conv2_pool2_conv3_tb/integrated_conv3_compared}
catch {add_wave /conv1_pool1_conv2_pool2_conv3_tb/mismatch_count}

puts "INFO: Running simulation for 260 ms..."
run 260 ms

puts "INFO: Simulation run command completed."
puts "CHECK TCL CONSOLE FOR:"
puts "  - Loaded counts OK: input=6000 expected=48000"
puts "  - PASS: integrated_conv3_compared=48000 mismatches=0"
puts "If PASS line is missing, search for FAIL or FIRST_INTEGRATED_CONV3_MISMATCH."
