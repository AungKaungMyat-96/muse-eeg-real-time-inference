# Add Muse CNN sources into the currently open Vivado project_1.
# This script does not create a new project or modify FPGA part settings.

set SRC_DIR "D:/Users/Lenovo/project_1/muse_cnn_sources/src"
set TB_DIR  "D:/Users/Lenovo/project_1/muse_cnn_sources/tb"
set XDC_DIR "D:/Users/Lenovo/project_1/muse_cnn_sources/constraints"

set design_files [list \
    "$SRC_DIR/conv1d_int8.v" \
    "$SRC_DIR/conv2_int32.v" \
    "$SRC_DIR/conv3_int32.v" \
    "$SRC_DIR/dense1_int32.v" \
    "$SRC_DIR/dense2_int32.v" \
    "$SRC_DIR/gap1d_int32.v" \
    "$SRC_DIR/maxpool2_int32.v" \
    "$SRC_DIR/relu_int32.v" \
    "$SRC_DIR/maxpool1d_int32.v" \
    "$SRC_DIR/relu.v" \
    "$SRC_DIR/maxpool.v" \
    "$SRC_DIR/dense.v" \
    "$SRC_DIR/top_cnn.v" \
    "$SRC_DIR/top_cnn_av7k325.v" \
]

set sim_files [list \
    "$TB_DIR/conv1d_tb.v" \
    "$TB_DIR/conv1_relu_pool_tb.v" \
    "$TB_DIR/conv2_tb.v" \
    "$TB_DIR/conv3_tb.v" \
    "$TB_DIR/dense1_tb.v" \
    "$TB_DIR/dense1_relu_tb.v" \
    "$TB_DIR/dense2_tb.v" \
    "$TB_DIR/full_inference_tb.v" \
    "$TB_DIR/gap_dense1_relu_dense2_tb.v" \
    "$TB_DIR/conv1_relu_pool_conv2_tb.v" \
    "$TB_DIR/conv1_pool1_conv2_pool2_conv3_tb.v" \
    "$TB_DIR/relu3_gap_tb.v" \
    "$TB_DIR/pool2_tb.v" \
]

set constr_files [list \
    "$XDC_DIR/top_cnn_av7k325.xdc" \
]

set missing_files [list]

foreach f $design_files {
    if {![file exists $f]} {
        puts "ERROR: Missing file: $f"
        lappend missing_files $f
    }
}

foreach f $sim_files {
    if {![file exists $f]} {
        puts "ERROR: Missing file: $f"
        lappend missing_files $f
    }
}

foreach f $constr_files {
    if {![file exists $f]} {
        puts "ERROR: Missing file: $f"
        lappend missing_files $f
    }
}

if {[llength $missing_files] > 0} {
    puts "ERROR: Source addition aborted due to missing files."
    return -code error
}

# Add design and simulation sources.
add_files -norecurse $design_files
add_files -fileset sim_1 -norecurse $sim_files
add_files -fileset constrs_1 -norecurse $constr_files

# Set top modules.
set_property top top_cnn_av7k325 [get_filesets sources_1]
set_property top conv1_relu_pool_tb [get_filesets sim_1]

# Update compile order.
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "SUCCESS: Muse CNN sources added to Vivado project_1."
