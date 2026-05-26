# -----------------------------------------------------------------------------
# run_milestone3_sim.tcl
# Purpose:
#   Run Milestone 3 behavioral simulation for Conv1 -> ReLU1 -> MaxPool1.
# Usage:
#   Open project_1 in Vivado, then in Tcl console:
#   source D:/Users/Lenovo/project_1/muse_cnn_sources/run_milestone3_sim.tcl
# -----------------------------------------------------------------------------

puts "INFO: Starting Milestone 3 Conv1->ReLU->MaxPool simulation flow..."

set_property top conv1_relu_pool_tb [get_filesets sim_1]
update_compile_order -fileset sim_1

if {[string equal [current_sim] ""]} {
    launch_simulation
} else {
    relaunch_sim
}

# Avoid huge array waves from TB memories.
catch {remove_wave [get_waves *input_mem*]}
catch {remove_wave [get_waves *relu_expected_mem*]}
catch {remove_wave [get_waves *pool_expected_mem*]}

# Keep only useful progress/IO signals.
catch {add_wave /conv1_relu_pool_tb/clk}
catch {add_wave /conv1_relu_pool_tb/rst_n}
catch {add_wave /conv1_relu_pool_tb/in_valid}
catch {add_wave /conv1_relu_pool_tb/in_data}
catch {add_wave /conv1_relu_pool_tb/conv_out_valid}
catch {add_wave /conv1_relu_pool_tb/conv_out_data}
catch {add_wave /conv1_relu_pool_tb/relu_out_valid}
catch {add_wave /conv1_relu_pool_tb/relu_out_data}
catch {add_wave /conv1_relu_pool_tb/pool_out_valid}
catch {add_wave /conv1_relu_pool_tb/pool_out_data}
catch {add_wave /conv1_relu_pool_tb/relu_compared_count}
catch {add_wave /conv1_relu_pool_tb/relu_mismatch_count}
catch {add_wave /conv1_relu_pool_tb/pool_compared_count}
catch {add_wave /conv1_relu_pool_tb/pool_mismatch_count}

puts "INFO: Running simulation for 25 ms..."
run 25 ms

puts "INFO: Simulation run command completed."
puts "CHECK TCL CONSOLE FOR:"
puts "  - Loaded counts OK"
puts "  - PASS: relu_compared=48000 relu_mismatches=0 maxpool_compared=24000 maxpool_mismatches=0"
puts "If PASS line is missing, search for FAIL/FIRST_RELU_MISMATCH/FIRST_MAXPOOL_MISMATCH."
