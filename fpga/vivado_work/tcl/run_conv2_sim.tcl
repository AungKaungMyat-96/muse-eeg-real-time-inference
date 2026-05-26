# -----------------------------------------------------------------------------
# run_conv2_sim.tcl
# Purpose:
#   Run Milestone 4A Conv2 standalone behavioral simulation.
# Usage:
#   Open project_1 in Vivado, then in Tcl console:
#   source D:/Users/Lenovo/project_1/muse_cnn_sources/run_conv2_sim.tcl
# -----------------------------------------------------------------------------

puts "INFO: Starting Milestone 4A Conv2 standalone simulation flow..."

set_property top conv2_tb [get_filesets sim_1]
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
catch {add_wave /conv2_tb/clk}
catch {add_wave /conv2_tb/rst_n}
catch {add_wave /conv2_tb/in_valid}
catch {add_wave /conv2_tb/in_data}
catch {add_wave /conv2_tb/out_valid}
catch {add_wave /conv2_tb/out_data}
catch {add_wave /conv2_tb/out_t_idx}
catch {add_wave /conv2_tb/out_f_idx}
catch {add_wave /conv2_tb/compared_count}
catch {add_wave /conv2_tb/mismatch_count}

puts "INFO: Running simulation for 35 ms..."
run 100 ms

puts "INFO: Simulation run command completed."
puts "CHECK TCL CONSOLE FOR:"
puts "  - Loaded counts OK: input=24000 expected=48000"
puts "  - PASS: compared=48000 mismatches=0"
puts "If PASS line is missing, search for FAIL or FIRST_MISMATCH."
