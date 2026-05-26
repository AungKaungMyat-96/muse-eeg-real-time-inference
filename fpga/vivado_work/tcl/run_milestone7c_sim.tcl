# -----------------------------------------------------------------------------
# run_milestone7c_sim.tcl
# Purpose:
#   Run Milestone 7C Dense1 ReLU standalone behavioral simulation.
# Usage:
#   Open project_1 in Vivado, then in Tcl console:
#   source D:/Users/Lenovo/project_1/muse_cnn_sources/run_milestone7c_sim.tcl
# -----------------------------------------------------------------------------

puts "INFO: Starting Milestone 7C Dense1 ReLU standalone simulation flow..."

set_property top dense1_relu_tb [get_filesets sim_1]
update_compile_order -fileset sim_1

if {[string equal [current_sim] ""]} {
    launch_simulation
} else {
    relaunch_sim
}

# Avoid huge testbench arrays in waveform.
catch {remove_wave [get_waves *input_mem*]}
catch {remove_wave [get_waves *expected_mem*]}

# Keep useful signals only.
catch {add_wave /dense1_relu_tb/clk}
catch {add_wave /dense1_relu_tb/rst_n}
catch {add_wave /dense1_relu_tb/in_valid}
catch {add_wave /dense1_relu_tb/in_data}
catch {add_wave /dense1_relu_tb/in_t_idx}
catch {add_wave /dense1_relu_tb/in_f_idx}
catch {add_wave /dense1_relu_tb/out_valid}
catch {add_wave /dense1_relu_tb/out_data}
catch {add_wave /dense1_relu_tb/out_t_idx}
catch {add_wave /dense1_relu_tb/out_f_idx}
catch {add_wave /dense1_relu_tb/dense1_relu_compared}
catch {add_wave /dense1_relu_tb/mismatch_count}

puts "INFO: Running simulation for 20 ms..."
run 20 ms

puts "INFO: Simulation run command completed."
puts "CHECK TCL CONSOLE FOR:"
puts "  - Loaded counts OK: input=32 expected=32"
puts "  - PASS: dense1_relu_compared=32 mismatches=0"
puts "If PASS line is missing, search for FAIL or FIRST_DENSE1_RELU_MISMATCH."
