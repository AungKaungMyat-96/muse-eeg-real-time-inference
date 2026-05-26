`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Module: top_cnn
// Description:
//   Top-level placeholder CNN pipeline:
//     Conv1D -> ReLU -> MaxPool -> Dense
//
//   This module wires the stage interfaces and propagates valid timing.
//   Layer internals are placeholders intended for incremental development.
// -----------------------------------------------------------------------------
module top_cnn #(
    parameter DATA_W = 8
)(
    input                        clk,
    input                        rst_n,
    input                        in_valid,
    input      signed [DATA_W-1:0] in_data,
    output                       out_valid,
    output     signed [DATA_W-1:0] out_data
);

    wire signed [DATA_W-1:0] conv_data;
    wire signed [DATA_W-1:0] relu_data;
    wire signed [DATA_W-1:0] pool_data;

    wire conv_valid;
    wire relu_valid;
    wire pool_valid;

    conv1d_int8 #(
        .DATA_W(DATA_W),
        .ACC_W(24)
    ) u_conv1d_int8 (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_data(in_data),
        .out_valid(conv_valid),
        .out_data(conv_data)
    );

    relu #(
        .DATA_W(DATA_W)
    ) u_relu (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(conv_valid),
        .in_data(conv_data),
        .out_valid(relu_valid),
        .out_data(relu_data)
    );

    maxpool #(
        .DATA_W(DATA_W)
    ) u_maxpool (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(relu_valid),
        .in_data(relu_data),
        .out_valid(pool_valid),
        .out_data(pool_data)
    );

    dense #(
        .DATA_W(DATA_W),
        .ACC_W(32)
    ) u_dense (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(pool_valid),
        .in_data(pool_data),
        .out_valid(out_valid),
        .out_data(out_data)
    );

endmodule
