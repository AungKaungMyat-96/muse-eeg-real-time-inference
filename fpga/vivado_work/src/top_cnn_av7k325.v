`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Module: top_cnn_av7k325
// Description:
//   Board-level wrapper for ALINX AV7K325 smoke testing.
//   - Converts differential system clock to single-ended internal clock.
//   - Instantiates top_cnn core without modifying core RTL.
//   - Uses fixed input stimulus for first hardware bring-up.
//   - Drives active-low user LEDs.
// -----------------------------------------------------------------------------
module top_cnn_av7k325 (
    input  sys_clk_p,
    input  sys_clk_n,
    input  key1,
    output led1,
    output led2
);

    wire clk_int;
    wire out_valid_w;
    wire signed [7:0] out_data_w;

    // Differential clock input buffer.
    IBUFDS u_ibufds_sysclk (
        .I(sys_clk_p),
        .IB(sys_clk_n),
        .O(clk_int)
    );

    // Core CNN top-level instance (unchanged core logic).
    top_cnn u_top_cnn (
        .clk(clk_int),
        .rst_n(key1),
        .in_valid(1'b1),
        .in_data(8'd1),
        .out_valid(out_valid_w),
        .out_data(out_data_w)
    );

    // AV7K325 user LEDs are active-low.
    assign led1 = ~out_valid_w;
    assign led2 = ~out_data_w[0];

endmodule
