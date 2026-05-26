`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Module: dense
// Description:
//   Placeholder fully connected (dense) layer block for INT8 pipeline.
//   This module currently forwards input data with registered timing while
//   preserving a wider accumulator register for future MAC integration.
// -----------------------------------------------------------------------------
module dense #(
    parameter DATA_W = 8,
    parameter ACC_W  = 32
)(
    input                        clk,
    input                        rst_n,
    input                        in_valid,
    input      signed [DATA_W-1:0] in_data,
    output reg                   out_valid,
    output reg signed [DATA_W-1:0] out_data
);

    reg signed [ACC_W-1:0] sum_reg;

    always @(posedge clk) begin
        if (!rst_n) begin
            sum_reg   <= {ACC_W{1'b0}};
            out_data  <= {DATA_W{1'b0}};
            out_valid <= 1'b0;
        end else begin
            out_valid <= in_valid;

            if (in_valid) begin
                // TODO: Replace with weighted sum and bias accumulation.
                sum_reg  <= {{(ACC_W-DATA_W){in_data[DATA_W-1]}}, in_data};
                out_data <= in_data;
            end
        end
    end

endmodule
