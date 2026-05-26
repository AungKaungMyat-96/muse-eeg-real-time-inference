`timescale 1ns/1ps

module dense2_int32 #(
    parameter IN_W = 32,
    parameter W_W = 8,
    parameter OUT_W = 32,
    parameter IN_DIM = 32,
    parameter OUT_DIM = 2
)(
    input                         clk,
    input                         rst_n,
    input                         in_valid,
    input      signed [IN_W-1:0]  in_data,
    output reg                    out_valid,
    output reg signed [OUT_W-1:0] out_data,
    output reg [7:0]              out_c_idx
);

    localparam S_IDLE     = 3'd0;
    localparam S_LOAD_IN  = 3'd1;
    localparam S_MAC_INIT = 3'd2;
    localparam S_MAC_RUN  = 3'd3;
    localparam S_BIAS_ADD = 3'd4;
    localparam S_WRITE    = 3'd5;
    localparam S_DONE     = 3'd6;

    reg [2:0] state;

    reg signed [IN_W-1:0] input_mem [0:IN_DIM-1];
    reg signed [W_W-1:0] weight_mem [0:(IN_DIM*OUT_DIM)-1];
    reg signed [OUT_W-1:0] bias_mem [0:OUT_DIM-1];

    reg [7:0] load_idx;
    reg [7:0] c_idx;
    reg [7:0] i_idx;

    reg signed [63:0] acc;

    integer i;
    integer wf;
    integer bf;
    integer code;
    integer temp_i;
    integer w_addr;
    reg signed [IN_W-1:0] x_val;
    reg signed [W_W-1:0] w_val;

    initial begin
        for (i = 0; i < (IN_DIM * OUT_DIM); i = i + 1) begin
            weight_mem[i] = {W_W{1'b0}};
        end
        for (i = 0; i < OUT_DIM; i = i + 1) begin
            bias_mem[i] = {OUT_W{1'b0}};
        end

        wf = $fopen("D:/Users/Lenovo/project_1/muse_cnn_sources/weights/dense2_w.mem", "r");
        if (wf != 0) begin
            i = 0;
            while ((i < (IN_DIM * OUT_DIM)) && (!$feof(wf))) begin
                code = $fscanf(wf, "%d\n", temp_i);
                if (code == 1) begin
                    weight_mem[i] = temp_i[W_W-1:0];
                    i = i + 1;
                end
            end
            $fclose(wf);
        end

        bf = $fopen("D:/Users/Lenovo/project_1/muse_cnn_sources/weights/dense2_b.mem", "r");
        if (bf != 0) begin
            i = 0;
            while ((i < OUT_DIM) && (!$feof(bf))) begin
                code = $fscanf(bf, "%d\n", temp_i);
                if (code == 1) begin
                    bias_mem[i] = temp_i;
                    i = i + 1;
                end
            end
            $fclose(bf);
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            state <= S_IDLE;
            out_valid <= 1'b0;
            out_data <= {OUT_W{1'b0}};
            out_c_idx <= 8'd0;

            load_idx <= 8'd0;
            c_idx <= 8'd0;
            i_idx <= 8'd0;
            acc <= 64'sd0;
        end else begin
            out_valid <= 1'b0;

            case (state)
                S_IDLE: begin
                    load_idx <= 8'd0;
                    c_idx <= 8'd0;
                    i_idx <= 8'd0;
                    acc <= 64'sd0;
                    out_c_idx <= 8'd0;

                    if (in_valid) begin
                        input_mem[0] <= in_data;
                        load_idx <= 8'd1;
                        state <= S_LOAD_IN;
                    end
                end

                S_LOAD_IN: begin
                    if (in_valid) begin
                        input_mem[load_idx] <= in_data;
                        if (load_idx == (IN_DIM - 1)) begin
                            state <= S_MAC_INIT;
                        end
                        load_idx <= load_idx + 8'd1;
                    end
                end

                S_MAC_INIT: begin
                    i_idx <= 8'd0;
                    acc <= 64'sd0;
                    state <= S_MAC_RUN;
                end

                S_MAC_RUN: begin
                    x_val = input_mem[i_idx];
                    w_addr = (c_idx * IN_DIM) + i_idx;
                    w_val = weight_mem[w_addr];

                    acc <= acc + (x_val * w_val);

                    if (i_idx == (IN_DIM - 1)) begin
                        state <= S_BIAS_ADD;
                    end else begin
                        i_idx <= i_idx + 8'd1;
                    end
                end

                S_BIAS_ADD: begin
                    acc <= acc + $signed(bias_mem[c_idx]);
                    state <= S_WRITE;
                end

                S_WRITE: begin
                    out_valid <= 1'b1;
                    out_data <= acc[OUT_W-1:0];
                    out_c_idx <= c_idx;

                    if (c_idx == (OUT_DIM - 1)) begin
                        state <= S_DONE;
                    end else begin
                        c_idx <= c_idx + 8'd1;
                        state <= S_MAC_INIT;
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
