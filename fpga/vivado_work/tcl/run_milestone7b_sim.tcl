# -----------------------------------------------------------------------------
# run_milestone7b_sim.tcl
# Purpose:
#   Run Milestone 7B Dense1 standalone behavioral simulation (raw pre-ReLU).
# Usage:
#   Open project_1 in Vivado, then in Tcl console:
#   source D:/Users/Lenovo/project_1/muse_cnn_sources/run_milestone7b_sim.tcl
# -----------------------------------------------------------------------------

puts "INFO: Starting Milestone 7B Dense1 standalone simulation flow..."

set_property top dense1_tb [get_filesets sim_1]
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
catch {add_wave /dense1_tb/clk}
catch {add_wave /dense1_tb/rst_n}
catch {add_wave /dense1_tb/in_valid}
catch {add_wave /dense1_tb/in_data}
catch {add_wave /dense1_tb/out_valid}
catch {add_wave /dense1_tb/out_data}
catch {add_wave /dense1_tb/out_o_idx}
catch {add_wave /dense1_tb/dense1_compared}
catch {add_wave /dense1_tb/mismatch_count}

puts "INFO: Running simulation for 20 ms..."
run 20 ms

puts "INFO: Simulation run command completed."
puts "CHECK TCL CONSOLE FOR:"
puts "  - Loaded counts OK: input=64 expected=32"
puts "  - PASS: dense1_compared=32 mismatches=0"
puts "If PASS line is missing, search for FAIL or FIRST_DENSE1_MISMATCH."
