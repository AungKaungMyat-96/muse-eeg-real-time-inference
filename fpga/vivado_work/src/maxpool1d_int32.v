`timescale 1ns/1ps

module maxpool1d_int32 #(
    parameter F_OUT = 16
)(
    input                       clk,
    input                       rst_n,
    input                       in_valid,
    input      signed [31:0]    in_data,
    input      [15:0]           in_t_idx,
    input      [7:0]            in_f_idx,
    output reg                  out_valid,
    output reg signed [31:0]    out_data,
    output reg [15:0]           out_t_pool_idx,
    output reg [7:0]            out_f_idx
);

    reg                         hold_valid [0:F_OUT-1];
    reg signed [31:0]           hold_data  [0:F_OUT-1];

    integer i;
    reg [7:0] f_sel;
    reg signed [31:0] a;
    reg signed [31:0] b;

    always @(posedge clk) begin
        if (!rst_n) begin
            out_valid      <= 1'b0;
            out_data       <= 32'sd0;
            out_t_pool_idx <= 16'd0;
            out_f_idx      <= 8'd0;

            for (i = 0; i < F_OUT; i = i + 1) begin
                hold_valid[i] <= 1'b0;
                hold_data[i]  <= 32'sd0;
            end
        end else begin
            out_valid <= 1'b0;

            if (in_valid) begin
                f_sel = in_f_idx;

                if (!hold_valid[f_sel]) begin
                    hold_valid[f_sel] <= 1'b1;
                    hold_data[f_sel]  <= in_data;
                end else begin
                    a = hold_data[f_sel];
                    b = in_data;

                    out_valid      <= 1'b1;
                    out_data       <= (a >= b) ? a : b;
                    out_t_pool_idx <= in_t_idx[15:1];
                    out_f_idx      <= in_f_idx;

                    hold_valid[f_sel] <= 1'b0;
                    hold_data[f_sel]  <= 32'sd0;
                end
            end
        end
    end

endmodule
