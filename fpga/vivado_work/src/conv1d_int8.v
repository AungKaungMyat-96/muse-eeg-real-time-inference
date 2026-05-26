`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Module: conv1d_int8
// Description:
//   Milestone 2 standalone Conv1D INT8 MAC engine for numerical verification.
//   - Loads full input stream first (6000 samples, flattened t->c)
//   - Uses loaded INT8 weights and INT32 bias from .mem files
//   - Computes SAME-padding Conv1D (stride=1) with sequential MAC
//   - Emits one INT32 output per (t,f) in order t=0..2999, f=0..15
//
// Notes:
//   - Verilog-2001 RTL
//   - Simulation/prototype initial file loading included for Milestone 2
// -----------------------------------------------------------------------------
module conv1d_int8 #(
    parameter DATA_W = 8,
    parameter OUT_W = 32,
    parameter L_IN = 3000,
    parameter C_IN = 2,
    parameter K = 7,
    parameter F_OUT = 16,
    parameter PAD_LEFT = 3
)(
    input                           clk,
    input                           rst_n,
    input                           in_valid,
    input      signed [DATA_W-1:0]  in_data,
    output reg                      out_valid,
    output reg signed [OUT_W-1:0]   out_data,
    output reg [15:0]               out_t_idx,
    output reg [7:0]                out_f_idx
);

    localparam INPUT_COUNT = L_IN * C_IN;
    localparam WEIGHT_COUNT = K * C_IN * F_OUT;

    localparam S_IDLE     = 3'd0;
    localparam S_LOAD_IN  = 3'd1;
    localparam S_MAC_INIT = 3'd2;
    localparam S_MAC_RUN  = 3'd3;
    localparam S_BIAS_ADD = 3'd4;
    localparam S_WRITE    = 3'd5;
    localparam S_DONE     = 3'd6;

    reg [2:0] state;

    reg signed [DATA_W-1:0] input_mem  [0:INPUT_COUNT-1];
    reg signed [DATA_W-1:0] weight_mem [0:WEIGHT_COUNT-1];
    reg signed [OUT_W-1:0]  bias_mem   [0:F_OUT-1];

    reg [15:0] load_idx;
    reg [15:0] t_idx;
    reg [7:0]  f_idx;
    reg [3:0]  k_idx;
    reg [1:0]  c_idx;

    reg signed [OUT_W-1:0] acc;

    integer i;
    integer wf;
    integer bf;
    integer code;
    integer temp_i;
    integer in_t;
    integer in_addr;
    integer w_addr;
    reg signed [DATA_W-1:0] x_val;
    reg signed [DATA_W-1:0] w_val;

    // -------------------------------------------------------------------------
    // Simulation/prototype file loading for Milestone 2 verification
    // -------------------------------------------------------------------------
    initial begin
        for (i = 0; i < WEIGHT_COUNT; i = i + 1) begin
            weight_mem[i] = {DATA_W{1'b0}};
        end
        for (i = 0; i < F_OUT; i = i + 1) begin
            bias_mem[i] = {OUT_W{1'b0}};
        end

        wf = $fopen("D:/Users/Lenovo/project_1/muse_cnn_sources/weights/conv1d_w.mem", "r");
        if (wf != 0) begin
            i = 0;
            while ((i < WEIGHT_COUNT) && (!$feof(wf))) begin
                code = $fscanf(wf, "%d\n", temp_i);
                if (code == 1) begin
                    weight_mem[i] = temp_i[DATA_W-1:0];
                    i = i + 1;
                end
            end
            $fclose(wf);
        end

        bf = $fopen("D:/Users/Lenovo/project_1/muse_cnn_sources/weights/conv1d_b.mem", "r");
        if (bf != 0) begin
            i = 0;
            while ((i < F_OUT) && (!$feof(bf))) begin
                code = $fscanf(bf, "%d\n", temp_i);
                if (code == 1) begin
                    bias_mem[i] = temp_i;
                    i = i + 1;
                end
            end
            $fclose(bf);
        end
    end

    // -------------------------------------------------------------------------
    // Main sequential control/data path
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            state     <= S_IDLE;
            out_valid <= 1'b0;
            out_data  <= {OUT_W{1'b0}};
            out_t_idx <= 16'd0;
            out_f_idx <= 8'd0;

            load_idx  <= 16'd0;
            t_idx     <= 16'd0;
            f_idx     <= 8'd0;
            k_idx     <= 4'd0;
            c_idx     <= 2'd0;
            acc       <= {OUT_W{1'b0}};
        end else begin
            out_valid <= 1'b0;

            case (state)
                S_IDLE: begin
                    load_idx <= 16'd0;
                    t_idx    <= 16'd0;
                    f_idx    <= 8'd0;
                    k_idx    <= 4'd0;
                    c_idx    <= 2'd0;
                    acc      <= {OUT_W{1'b0}};

                    if (in_valid) begin
                        input_mem[0] <= in_data;
                        load_idx     <= 16'd1;
                        state        <= S_LOAD_IN;
                    end
                end

                S_LOAD_IN: begin
                    if (in_valid) begin
                        input_mem[load_idx] <= in_data;
                        if (load_idx == (INPUT_COUNT - 1)) begin
                            state <= S_MAC_INIT;
                        end
                        load_idx <= load_idx + 16'd1;
                    end
                end

                S_MAC_INIT: begin
                    k_idx <= 4'd0;
                    c_idx <= 2'd0;
                    acc   <= {OUT_W{1'b0}};
                    state <= S_MAC_RUN;
                end

                S_MAC_RUN: begin
                    in_t = t_idx + k_idx - PAD_LEFT;
                    if ((in_t < 0) || (in_t >= L_IN)) begin
                        x_val = {DATA_W{1'b0}};
                    end else begin
                        in_addr = in_t * C_IN + c_idx;
                        x_val = input_mem[in_addr];
                    end

                    w_addr = (f_idx * K * C_IN) + (k_idx * C_IN) + c_idx;
                    w_val = weight_mem[w_addr];

                    acc <= acc + (x_val * w_val);

                    if (c_idx == (C_IN - 1)) begin
                        c_idx <= 2'd0;
                        if (k_idx == (K - 1)) begin
                            state <= S_BIAS_ADD;
                        end else begin
                            k_idx <= k_idx + 4'd1;
                        end
                    end else begin
                        c_idx <= c_idx + 2'd1;
                    end
                end

                S_BIAS_ADD: begin
                    acc <= acc + bias_mem[f_idx];
                    state <= S_WRITE;
                end

                S_WRITE: begin
                    out_valid <= 1'b1;
                    out_data  <= acc;
                    out_t_idx <= t_idx;
                    out_f_idx <= f_idx;

                    if (f_idx == (F_OUT - 1)) begin
                        f_idx <= 8'd0;
                        if (t_idx == (L_IN - 1)) begin
                            state <= S_DONE;
                        end else begin
                            t_idx <= t_idx + 16'd1;
                            state <= S_MAC_INIT;
                        end
                    end else begin
                        f_idx <= f_idx + 8'd1;
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
