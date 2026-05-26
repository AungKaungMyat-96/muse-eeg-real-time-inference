# -----------------------------------------------------------------------------
# run_milestone9_sim.tcl
# Purpose:
#   Run Milestone 9 full end-to-end FPGA inference behavioral simulation.
# Usage:
#   Open project_1 in Vivado, then in Tcl console:
#   source D:/Users/Lenovo/project_1/muse_cnn_sources/run_milestone9_sim.tcl
# -----------------------------------------------------------------------------

puts "INFO: Starting Milestone 9 full end-to-end inference simulation flow..."

set_property top full_inference_tb [get_filesets sim_1]
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
catch {remove_wave [get_waves *sum_mem*]}
catch {remove_wave [get_waves *hold_data*]}

# Keep useful stage and progress signals.
catch {add_wave /full_inference_tb/clk}
catch {add_wave /full_inference_tb/rst_n}
catch {add_wave /full_inference_tb/in_valid}
catch {add_wave /full_inference_tb/in_data}

catch {add_wave /full_inference_tb/conv1_out_valid}
catch {add_wave /full_inference_tb/relu1_out_valid}
catch {add_wave /full_inference_tb/pool1_out_valid}
catch {add_wave /full_inference_tb/conv2_out_valid}
catch {add_wave /full_inference_tb/pool2_out_valid}
catch {add_wave /full_inference_tb/conv3_out_valid}
catch {add_wave /full_inference_tb/relu3_out_valid}
catch {add_wave /full_inference_tb/gap_out_valid}
catch {add_wave /full_inference_tb/dense1_out_valid}
catch {add_wave /full_inference_tb/dense1_relu_out_valid}
catch {add_wave /full_inference_tb/dense2_out_valid}
catch {add_wave /full_inference_tb/dense2_out_data}
catch {add_wave /full_inference_tb/dense2_out_c_idx}

catch {add_wave /full_inference_tb/conv1_count}
catch {add_wave /full_inference_tb/relu1_count}
catch {add_wave /full_inference_tb/pool1_count}
catch {add_wave /full_inference_tb/conv2_count}
catch {add_wave /full_inference_tb/pool2_count}
catch {add_wave /full_inference_tb/conv3_count}
catch {add_wave /full_inference_tb/relu3_count}
catch {add_wave /full_inference_tb/gap_count}
catch {add_wave /full_inference_tb/dense1_count}
catch {add_wave /full_inference_tb/dense1_relu_count}
catch {add_wave /full_inference_tb/dense2_count}
catch {add_wave /full_inference_tb/full_inference_compared}
catch {add_wave /full_inference_tb/mismatch_count}

puts "INFO: Running simulation for 450 ms..."
run 450 ms

puts "INFO: Simulation run command completed."
puts "CHECK TCL CONSOLE FOR:"
puts "  - Loaded counts OK: input=6000 expected=2"
puts "  - PASS: full_inference_compared=2 mismatches=0"
puts "If PASS line is missing, search for FAIL or FIRST_FULL_INFERENCE_MISMATCH."
