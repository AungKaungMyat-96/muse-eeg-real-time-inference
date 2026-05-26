`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Module: relu
// Description:
//   Placeholder ReLU activation block for signed INT8 data.
//   Performs a clocked max(0, x) operation and forwards valid timing.
// -----------------------------------------------------------------------------
module relu #(
    parameter DATA_W = 8
)(
    input                        clk,
    input                        rst_n,
    input                        in_valid,
    input      signed [DATA_W-1:0] in_data,
    output reg                   out_valid,
    output reg signed [DATA_W-1:0] out_data
);

    always @(posedge clk) begin
        if (!rst_n) begin
            out_data  <= {DATA_W{1'b0}};
            out_valid <= 1'b0;
        end else begin
            out_valid <= in_valid;

            if (in_valid) begin
                // ReLU in fixed-point signed domain.
                if (in_data[DATA_W-1] == 1'b1) begin
                    out_data <= {DATA_W{1'b0}};
                end else begin
                    out_data <= in_data;
                end
            end
        end
    end

endmodule
