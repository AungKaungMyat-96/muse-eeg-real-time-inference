# -----------------------------------------------------------------------------
# run_milestone10a_synth_impl.tcl
# Purpose:
#   Milestone 10A synthesis/implementation flow for inference_top_av7k325.
#   Default mode is synthesis-only smoke test.
# Usage:
#   Open project_1 in Vivado, then in Tcl console:
#   source D:/Users/Lenovo/project_1/muse_cnn_sources/run_milestone10a_synth_impl.tcl
# Optional mode override before source:
#   set M10A_MODE full
# -----------------------------------------------------------------------------

set REPORT_DIR "D:/Users/Lenovo/project_1/muse_cnn_sources/reports"
file mkdir $REPORT_DIR

set SRC_ROOT "D:/Users/Lenovo/project_1/muse_cnn_sources"
set new_top_v "D:/Users/Lenovo/project_1/muse_cnn_sources/src/inference_top_av7k325.v"
set new_xdc "D:/Users/Lenovo/project_1/muse_cnn_sources/constraints/inference_top_av7k325.xdc"

set hex_files [list \
    "$SRC_ROOT/data/hex/conv1d_input_i8.hex" \
    "$SRC_ROOT/weights/hex/conv1d_w_i8.hex" \
    "$SRC_ROOT/weights/hex/conv1d_b_i32.hex" \
    "$SRC_ROOT/weights/hex/conv2_w_i8.hex" \
    "$SRC_ROOT/weights/hex/conv2_b_i32.hex" \
    "$SRC_ROOT/weights/hex/conv3_w_i8.hex" \
    "$SRC_ROOT/weights/hex/conv3_b_i32.hex" \
    "$SRC_ROOT/weights/hex/dense1_w_i8.hex" \
    "$SRC_ROOT/weights/hex/dense1_b_i32.hex" \
    "$SRC_ROOT/weights/hex/dense2_w_i8.hex" \
    "$SRC_ROOT/weights/hex/dense2_b_i32.hex" \
]

if {![info exists M10A_MODE]} {
    set M10A_MODE "synth_only"
}

puts "INFO: Starting Milestone 10A synth/impl flow..."

if {[string equal [current_project] ""]} {
    puts "ERROR: No project is currently open. Open project_1.xpr first."
    return -code error
}

if {![file exists $new_xdc]} {
    puts "ERROR: Missing constraint file: $new_xdc"
    return -code error
}

if {![file exists $new_top_v]} {
    puts "ERROR: Missing top RTL file: $new_top_v"
    return -code error
}

foreach hf $hex_files {
    if {![file exists $hf]} {
        puts "ERROR: Missing deployment HEX file: $hf"
        return -code error
    }
}

# Ensure top RTL is part of sources_1.
set top_v_files [get_files -all -quiet $new_top_v]
if {[llength $top_v_files] == 0} {
    add_files -fileset sources_1 -norecurse $new_top_v
}

# Ensure new constraint file is part of constrs_1.
set xdc_files [get_files -all -quiet $new_xdc]
if {[llength $xdc_files] == 0} {
    add_files -fileset constrs_1 -norecurse $new_xdc
}

# Ensure deployment HEX files are tracked in sources_1.
foreach hf $hex_files {
    set hf_in_proj [get_files -all -quiet $hf]
    if {[llength $hf_in_proj] == 0} {
        add_files -fileset sources_1 -norecurse $hf
    }
}

set_property source_mgmt_mode None [current_project]
set_property top inference_top_av7k325 [get_filesets sources_1]
update_compile_order -fileset sources_1

puts "INFO: Launching synthesis run..."
reset_run synth_1

# Stage HEX files into synth run working directory so relative $readmemh paths
# resolve correctly during synth_1 execution.
set SYNTH_RUN_DIR "D:/Users/Lenovo/project_1/project_1.runs/synth_1"
set synth_data_hex_dir "$SYNTH_RUN_DIR/data/hex"
set synth_weights_hex_dir "$SYNTH_RUN_DIR/weights/hex"
file mkdir $synth_data_hex_dir
file mkdir $synth_weights_hex_dir

file copy -force "$SRC_ROOT/data/hex/conv1d_input_i8.hex" "$synth_data_hex_dir/conv1d_input_i8.hex"
file copy -force "$SRC_ROOT/weights/hex/conv1d_w_i8.hex" "$synth_weights_hex_dir/conv1d_w_i8.hex"
file copy -force "$SRC_ROOT/weights/hex/conv1d_b_i32.hex" "$synth_weights_hex_dir/conv1d_b_i32.hex"
file copy -force "$SRC_ROOT/weights/hex/conv2_w_i8.hex" "$synth_weights_hex_dir/conv2_w_i8.hex"
file copy -force "$SRC_ROOT/weights/hex/conv2_b_i32.hex" "$synth_weights_hex_dir/conv2_b_i32.hex"
file copy -force "$SRC_ROOT/weights/hex/conv3_w_i8.hex" "$synth_weights_hex_dir/conv3_w_i8.hex"
file copy -force "$SRC_ROOT/weights/hex/conv3_b_i32.hex" "$synth_weights_hex_dir/conv3_b_i32.hex"
file copy -force "$SRC_ROOT/weights/hex/dense1_w_i8.hex" "$synth_weights_hex_dir/dense1_w_i8.hex"
file copy -force "$SRC_ROOT/weights/hex/dense1_b_i32.hex" "$synth_weights_hex_dir/dense1_b_i32.hex"
file copy -force "$SRC_ROOT/weights/hex/dense2_w_i8.hex" "$synth_weights_hex_dir/dense2_w_i8.hex"
file copy -force "$SRC_ROOT/weights/hex/dense2_b_i32.hex" "$synth_weights_hex_dir/dense2_b_i32.hex"

launch_runs synth_1 -jobs 4
wait_on_run synth_1

set synth_status [get_property STATUS [get_runs synth_1]]
puts "INFO: synth_1 status: $synth_status"
if {![string match "*synth_design Complete*" $synth_status]} {
    puts "ERROR: Synthesis failed or did not complete. Aborting flow."
    return -code error
}

open_run synth_1
report_utilization -file "$REPORT_DIR/m10a_synth_util.rpt"
report_timing_summary -file "$REPORT_DIR/m10a_synth_timing_precheck.rpt"

if {$M10A_MODE eq "synth_only"} {
    puts "INFO: Synth-only mode complete."
    puts "Reports generated in: $REPORT_DIR"
    return
}

puts "INFO: Launching implementation run through bitstream..."
reset_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

open_run impl_1
report_utilization -file "$REPORT_DIR/m10a_impl_util.rpt"
report_timing_summary -file "$REPORT_DIR/m10a_timing.rpt"
report_power -file "$REPORT_DIR/m10a_power.rpt"

set impl_status [get_property STATUS [get_runs impl_1]]
puts "INFO: impl_1 status: $impl_status"
if {[string match "*write_bitstream Complete*" $impl_status]} {
    puts "INFO: Bitstream generation completed."
} else {
    puts "WARNING: Bitstream may not be complete. Check impl_1 status and logs."
}

puts "INFO: Milestone 10A synth/impl flow finished."
puts "Reports generated in: $REPORT_DIR"
