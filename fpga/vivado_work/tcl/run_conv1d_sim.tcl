# -----------------------------------------------------------------------------
# run_conv1d_sim.tcl
# Purpose:
#   Run full Milestone 2 Conv1D behavioral simulation (not 1000ns short run).
# Usage:
#   Open project_1 in Vivado, then in Tcl console:
#   source D:/Users/Lenovo/project_1/muse_cnn_sources/run_conv1d_sim.tcl
# -----------------------------------------------------------------------------

puts "INFO: Starting Milestone 2 Conv1D full simulation flow..."

# Ensure sim top is conv1d_tb
set_property top conv1d_tb [get_filesets sim_1]
update_compile_order -fileset sim_1

# Relaunch behavioral simulation cleanly
if {[string equal [current_sim] ""]} {
    launch_simulation
} else {
    relaunch_sim
}

# Reduce unnecessary wave objects; avoid huge memory arrays
# (expected_mem/input_mem/weight_mem/bias_mem are large and not useful in waves)
catch {remove_wave [get_waves *expected_mem*]}
catch {remove_wave [get_waves *input_mem*]}
catch {remove_wave [get_waves *weight_mem*]}
catch {remove_wave [get_waves *bias_mem*]}

# Keep only useful DUT and TB control/output signals
catch {add_wave /conv1d_tb/clk}
catch {add_wave /conv1d_tb/rst_n}
catch {add_wave /conv1d_tb/in_valid}
catch {add_wave /conv1d_tb/in_data}
catch {add_wave /conv1d_tb/out_valid}
catch {add_wave /conv1d_tb/out_data}
catch {add_wave /conv1d_tb/compared_count}
catch {add_wave /conv1d_tb/mismatch_count}
catch {add_wave /conv1d_tb/first_mismatch_reported}

puts "INFO: Running simulation for 20 ms (full Conv1D test window)..."
run 20 ms

puts "INFO: Simulation run command completed."
puts "CHECK TCL CONSOLE FOR:"
puts "  - Loaded counts OK"
puts "  - PASS: compared=48000 mismatches=0"
puts "If PASS line is missing, search for FAIL or FIRST_MISMATCH."
