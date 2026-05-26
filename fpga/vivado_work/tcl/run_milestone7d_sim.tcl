# -----------------------------------------------------------------------------
# run_milestone7d_sim.tcl
# Purpose:
#   Run Milestone 7D Dense2 logits standalone behavioral simulation.
# Usage:
#   Open project_1 in Vivado, then in Tcl console:
#   source D:/Users/Lenovo/project_1/muse_cnn_sources/run_milestone7d_sim.tcl
# -----------------------------------------------------------------------------

puts "INFO: Starting Milestone 7D Dense2 logits standalone simulation flow..."

set_property top dense2_tb [get_filesets sim_1]
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

# Keep useful signals only.
catch {add_wave /dense2_tb/clk}
catch {add_wave /dense2_tb/rst_n}
catch {add_wave /dense2_tb/in_valid}
catch {add_wave /dense2_tb/in_data}
catch {add_wave /dense2_tb/out_valid}
catch {add_wave /dense2_tb/out_data}
catch {add_wave /dense2_tb/out_c_idx}
catch {add_wave /dense2_tb/dense2_compared}
catch {add_wave /dense2_tb/mismatch_count}

puts "INFO: Running simulation for 20 ms..."
run 20 ms

puts "INFO: Simulation run command completed."
puts "CHECK TCL CONSOLE FOR:"
puts "  - Loaded counts OK: input=32 expected=2"
puts "  - PASS: dense2_compared=2 mismatches=0"
puts "If PASS line is missing, search for FAIL or FIRST_DENSE2_MISMATCH."
