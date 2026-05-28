# -----------------------------------------------------------------------------
# run_milestone10e_classifier_synth_impl.tcl
# Purpose:
#   Milestone 10E classifier-only synthesis/implementation flow.
#   Default mode is synthesis-only smoke test.
# Usage:
#   source D:/Users/Lenovo/project_1/muse_cnn_sources/run_milestone10e_classifier_synth_impl.tcl
# Optional mode override before source:
#   set M10E_MODE full
# -----------------------------------------------------------------------------

set REPORT_DIR "D:/Users/Lenovo/project_1/muse_cnn_sources/reports"
file mkdir $REPORT_DIR

set SRC_ROOT "D:/Users/Lenovo/project_1/muse_cnn_sources"
set top_v "D:/Users/Lenovo/project_1/muse_cnn_sources/src/classifier_top_av7k325.v"
set xdc_classifier_200 "D:/Users/Lenovo/project_1/muse_cnn_sources/constraints/classifier_top_av7k325.xdc"
set xdc_classifier_100 "D:/Users/Lenovo/project_1/muse_cnn_sources/constraints/classifier_top_av7k325_100mhz.xdc"
set xdc_top_cnn "D:/Users/Lenovo/project_1/muse_cnn_sources/constraints/top_cnn_av7k325.xdc"
set xdc_inference "D:/Users/Lenovo/project_1/muse_cnn_sources/constraints/inference_top_av7k325.xdc"

if {![info exists M10E_XDC]} {
    set M10E_XDC $xdc_classifier_100
}

set hex_files [list \
    "$SRC_ROOT/data/hex/gap_expected_i32.hex" \
    "$SRC_ROOT/weights/hex/dense1_w_i8.hex" \
    "$SRC_ROOT/weights/hex/dense1_b_i32.hex" \
    "$SRC_ROOT/weights/hex/dense2_w_i8.hex" \
    "$SRC_ROOT/weights/hex/dense2_b_i32.hex" \
]

if {![info exists M10E_MODE]} {
    set M10E_MODE "synth_only"
}

puts "INFO: Starting Milestone 10E classifier synth/impl flow..."

if {[string equal [current_project] ""]} {
    puts "ERROR: No project is currently open. Open project_1.xpr first."
    return -code error
}

if {![file exists $top_v]} {
    puts "ERROR: Missing top RTL file: $top_v"
    return -code error
}

if {![file exists $M10E_XDC]} {
    puts "ERROR: Missing selected constraint file: $M10E_XDC"
    return -code error
}

foreach hf $hex_files {
    if {![file exists $hf]} {
        puts "ERROR: Missing classifier HEX file: $hf"
        return -code error
    }
}

set top_files [get_files -all -quiet $top_v]
if {[llength $top_files] == 0} {
    add_files -fileset sources_1 -norecurse $top_v
}

set xdc_files [get_files -all -quiet $M10E_XDC]
if {[llength $xdc_files] == 0} {
    add_files -fileset constrs_1 -norecurse $M10E_XDC
}

# Add optional classifier 200 MHz XDC if present so its usage can be controlled.
if {[file exists $xdc_classifier_200]} {
    set xdc200_files [get_files -all -quiet $xdc_classifier_200]
    if {[llength $xdc200_files] == 0} {
        add_files -fileset constrs_1 -norecurse $xdc_classifier_200
    }
}

# Ensure non-classifier deployment XDCs are not used for this run.
if {[llength [get_files -all -quiet $xdc_top_cnn]] > 0} {
    set_property used_in_synthesis false [get_files $xdc_top_cnn]
    set_property used_in_implementation false [get_files $xdc_top_cnn]
}
if {[llength [get_files -all -quiet $xdc_inference]] > 0} {
    set_property used_in_synthesis false [get_files $xdc_inference]
    set_property used_in_implementation false [get_files $xdc_inference]
}

# Use selected classifier XDC; disable alternate classifier XDC to avoid duplicate clocks.
if {[llength [get_files -all -quiet $M10E_XDC]] > 0} {
    set_property used_in_synthesis true [get_files $M10E_XDC]
    set_property used_in_implementation true [get_files $M10E_XDC]
}
if {[file exists $xdc_classifier_200] && ($M10E_XDC ne $xdc_classifier_200) && ([llength [get_files -all -quiet $xdc_classifier_200]] > 0)} {
    set_property used_in_synthesis false [get_files $xdc_classifier_200]
    set_property used_in_implementation false [get_files $xdc_classifier_200]
}
if {($M10E_XDC ne $xdc_classifier_100) && ([llength [get_files -all -quiet $xdc_classifier_100]] > 0)} {
    set_property used_in_synthesis false [get_files $xdc_classifier_100]
    set_property used_in_implementation false [get_files $xdc_classifier_100]
}

foreach hf $hex_files {
    set hf_in_proj [get_files -all -quiet $hf]
    if {[llength $hf_in_proj] == 0} {
        add_files -fileset sources_1 -norecurse $hf
    }
}

set_property source_mgmt_mode None [current_project]
set_property top classifier_top_av7k325 [get_filesets sources_1]
update_compile_order -fileset sources_1

puts "INFO: Launching synthesis run..."
reset_run synth_1

set SYNTH_RUN_DIR "D:/Users/Lenovo/project_1/project_1.runs/synth_1"
set synth_data_hex_dir "$SYNTH_RUN_DIR/data/hex"
set synth_weights_hex_dir "$SYNTH_RUN_DIR/weights/hex"
file mkdir $synth_data_hex_dir
file mkdir $synth_weights_hex_dir

file copy -force "$SRC_ROOT/data/hex/gap_expected_i32.hex" "$synth_data_hex_dir/gap_expected_i32.hex"
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
report_utilization -file "$REPORT_DIR/m10e_classifier_synth_util.rpt"
report_timing_summary -file "$REPORT_DIR/m10e_classifier_timing_precheck.rpt"

if {$M10E_MODE eq "synth_only"} {
    puts "INFO: Milestone 10E synth-only mode complete."
    puts "Reports generated in: $REPORT_DIR"
    return
}

puts "INFO: Launching implementation run through bitstream..."
reset_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

open_run impl_1
report_utilization -file "$REPORT_DIR/m10e_classifier_impl_util.rpt"
report_timing_summary -file "$REPORT_DIR/m10e_classifier_timing_impl.rpt"
report_power -file "$REPORT_DIR/m10e_classifier_power.rpt"

set impl_status [get_property STATUS [get_runs impl_1]]
puts "INFO: impl_1 status: $impl_status"
if {[string match "*write_bitstream Complete*" $impl_status]} {
    puts "INFO: Bitstream generation completed."
} else {
    puts "WARNING: Bitstream may not be complete. Check impl_1 status and logs."
}

puts "INFO: Milestone 10E classifier synth/impl flow finished."
puts "Reports generated in: $REPORT_DIR"
