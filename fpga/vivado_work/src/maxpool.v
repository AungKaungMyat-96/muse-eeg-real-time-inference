`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Module: maxpool
// Description:
//   Placeholder 1D max-pooling block for signed INT8 data.
//   Current implementation compares pairs of valid samples and emits one pooled
//   result every two valid inputs.
//
// Notes:
//   - This is a simplified placeholder for future configurable window/stride.
// -----------------------------------------------------------------------------
module maxpool #(
    parameter DATA_W = 8
)(
    input                        clk,
    input                        rst_n,
    input                        in_valid,
    input      signed [DATA_W-1:0] in_data,
    output reg                   out_valid,
    output reg signed [DATA_W-1:0] out_data
);

    reg signed [DATA_W-1:0] sample_hold;
    reg                      sample_hold_valid;

    always @(posedge clk) begin
        if (!rst_n) begin
            sample_hold       <= {DATA_W{1'b0}};
            sample_hold_valid <= 1'b0;
            out_data          <= {DATA_W{1'b0}};
            out_valid         <= 1'b0;
        end else begin
            out_valid <= 1'b0;

            if (in_valid) begin
                if (!sample_hold_valid) begin
                    sample_hold       <= in_data;
                    sample_hold_valid <= 1'b1;
                end else begin
                    // Pairwise max operation as placeholder pooling behavior.
                    if (in_data > sample_hold) begin
                        out_data <= in_data;
                    end else begin
                        out_data <= sample_hold;
                    end
                    out_valid         <= 1'b1;
                    sample_hold_valid <= 1'b0;
                end
            end
        end
    end

endmodule
