# -----------------------------------------------------------------------------
# run_milestone5a_sim.tcl
# Purpose:
#   Run Milestone 5A behavioral simulation for Pool2 standalone verification.
# Usage:
#   Open project_1 in Vivado, then in Tcl console:
#   source D:/Users/Lenovo/project_1/muse_cnn_sources/run_milestone5a_sim.tcl
# -----------------------------------------------------------------------------

puts "INFO: Starting Milestone 5A Pool2 standalone simulation flow..."

set_property top pool2_tb [get_filesets sim_1]
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
catch {add_wave /pool2_tb/clk}
catch {add_wave /pool2_tb/rst_n}
catch {add_wave /pool2_tb/in_valid}
catch {add_wave /pool2_tb/in_data}
catch {add_wave /pool2_tb/in_t_idx}
catch {add_wave /pool2_tb/in_f_idx}
catch {add_wave /pool2_tb/out_valid}
catch {add_wave /pool2_tb/out_data}
catch {add_wave /pool2_tb/out_t_pool_idx}
catch {add_wave /pool2_tb/out_f_idx}
catch {add_wave /pool2_tb/pool2_compared}
catch {add_wave /pool2_tb/mismatch_count}

puts "INFO: Running simulation for 30 ms..."
run 30 ms

puts "INFO: Simulation run command completed."
puts "CHECK TCL CONSOLE FOR:"
puts "  - Loaded counts OK: input=48000 expected=24000"
puts "  - PASS: pool2_compared=24000 mismatches=0"
puts "If PASS line is missing, search for FAIL or FIRST_POOL2_MISMATCH."
