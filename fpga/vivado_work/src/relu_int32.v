`timescale 1ns/1ps

module relu_int32 (
    input                       clk,
    input                       rst_n,
    input                       in_valid,
    input      signed [31:0]    in_data,
    input      [15:0]           in_t_idx,
    input      [7:0]            in_f_idx,
    output reg                  out_valid,
    output reg signed [31:0]    out_data,
    output reg [15:0]           out_t_idx,
    output reg [7:0]            out_f_idx
);

    always @(posedge clk) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            out_data  <= 32'sd0;
            out_t_idx <= 16'd0;
            out_f_idx <= 8'd0;
        end else begin
            out_valid <= in_valid;
            out_t_idx <= in_t_idx;
            out_f_idx <= in_f_idx;

            if (in_data < 0) begin
                out_data <= 32'sd0;
            end else begin
                out_data <= in_data;
            end
        end
    end

endmodule
