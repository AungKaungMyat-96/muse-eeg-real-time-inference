`timescale 1ns/1ps

module gap1d_int32 #(
    parameter L_IN = 750,
    parameter F_OUT = 64
)(
    input                      clk,
    input                      rst_n,
    input                      in_valid,
    input      signed [31:0]   in_data,
    output reg                 out_valid,
    output reg signed [31:0]   out_data,
    output reg [7:0]           out_f_idx
);

    localparam INPUT_COUNT = L_IN * F_OUT;

    localparam S_IDLE  = 2'd0;
    localparam S_ACCUM = 2'd1;
    localparam S_OUT   = 2'd2;
    localparam S_DONE  = 2'd3;

    reg [1:0] state;

    reg signed [63:0] sum_mem [0:F_OUT-1];

    reg [31:0] in_count;
    reg [7:0]  f_idx_accum;
    reg [7:0]  f_idx_out;

    integer i;

    always @(posedge clk) begin
        if (!rst_n) begin
            state <= S_IDLE;
            out_valid <= 1'b0;
            out_data <= 32'sd0;
            out_f_idx <= 8'd0;
            in_count <= 32'd0;
            f_idx_accum <= 8'd0;
            f_idx_out <= 8'd0;

            for (i = 0; i < F_OUT; i = i + 1) begin
                sum_mem[i] <= 64'sd0;
            end
        end else begin
            out_valid <= 1'b0;

            case (state)
                S_IDLE: begin
                    in_count <= 32'd0;
                    f_idx_accum <= 8'd0;
                    f_idx_out <= 8'd0;
                    out_f_idx <= 8'd0;
                    for (i = 0; i < F_OUT; i = i + 1) begin
                        sum_mem[i] <= 64'sd0;
                    end

                    if (in_valid) begin
                        sum_mem[0] <= sum_mem[0] + $signed(in_data);
                        in_count <= 32'd1;
                        f_idx_accum <= 8'd1;
                        state <= S_ACCUM;
                    end
                end

                S_ACCUM: begin
                    if (in_valid) begin
                        sum_mem[f_idx_accum] <= sum_mem[f_idx_accum] + $signed(in_data);

                        if (in_count == (INPUT_COUNT - 1)) begin
                            state <= S_OUT;
                            f_idx_out <= 8'd0;
                        end

                        in_count <= in_count + 32'd1;

                        if (f_idx_accum == (F_OUT - 1)) begin
                            f_idx_accum <= 8'd0;
                        end else begin
                            f_idx_accum <= f_idx_accum + 8'd1;
                        end
                    end
                end

                S_OUT: begin
                    out_valid <= 1'b1;
                    out_f_idx <= f_idx_out;
                    out_data <= sum_mem[f_idx_out] / L_IN;

                    if (f_idx_out == (F_OUT - 1)) begin
                        state <= S_DONE;
                    end else begin
                        f_idx_out <= f_idx_out + 8'd1;
                    end
                end

                S_DONE: begin
                    state <= S_DONE;
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule
