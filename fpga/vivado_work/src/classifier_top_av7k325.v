`timescale 1ns/1ps

module classifier_top_av7k325 (
    input  sys_clk_p,
    input  sys_clk_n,
    input  key1,
    output led_done,
    output led_class
);

    localparam GAP_COUNT = 64;

    localparam S_IDLE = 2'd0;
    localparam S_RUN  = 2'd1;
    localparam S_DONE = 2'd2;

    wire clk_int;
    wire rst_n;

    reg [1:0] state;
    reg [7:0] in_idx;
    reg in_valid;
    reg signed [31:0] in_data;

    reg done_reg;
    reg signed [31:0] logit0_reg;
    reg signed [31:0] logit1_reg;

    reg signed [31:0] gap_mem [0:GAP_COUNT-1];

    wire dense1_out_valid;
    wire signed [31:0] dense1_out_data;
    wire [7:0] dense1_out_o_idx;

    wire dense1_relu_out_valid;
    wire signed [31:0] dense1_relu_out_data;
    wire [15:0] dense1_relu_out_t_idx;
    wire [7:0] dense1_relu_out_f_idx;

    wire dense2_out_valid;
    wire signed [31:0] dense2_out_data;
    wire [7:0] dense2_out_c_idx;

    integer i;

    assign rst_n = key1;

    IBUFDS u_ibufds_sysclk (
        .I(sys_clk_p),
        .IB(sys_clk_n),
        .O(clk_int)
    );

    initial begin
        for (i = 0; i < GAP_COUNT; i = i + 1) begin
            gap_mem[i] = 32'sd0;
        end
        $readmemh("data/hex/gap_expected_i32.hex", gap_mem);
    end

    dense1_int32 #(
        .IN_W(32),
        .W_W(8),
        .OUT_W(32),
        .IN_DIM(64),
        .OUT_DIM(32)
    ) u_dense1 (
        .clk(clk_int),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_data(in_data),
        .out_valid(dense1_out_valid),
        .out_data(dense1_out_data),
        .out_o_idx(dense1_out_o_idx)
    );

    relu_int32 u_relu_dense1 (
        .clk(clk_int),
        .rst_n(rst_n),
        .in_valid(dense1_out_valid),
        .in_data(dense1_out_data),
        .in_t_idx(16'd0),
        .in_f_idx(dense1_out_o_idx),
        .out_valid(dense1_relu_out_valid),
        .out_data(dense1_relu_out_data),
        .out_t_idx(dense1_relu_out_t_idx),
        .out_f_idx(dense1_relu_out_f_idx)
    );

    dense2_int32 #(
        .IN_W(32),
        .W_W(8),
        .OUT_W(32),
        .IN_DIM(32),
        .OUT_DIM(2)
    ) u_dense2 (
        .clk(clk_int),
        .rst_n(rst_n),
        .in_valid(dense1_relu_out_valid),
        .in_data(dense1_relu_out_data),
        .out_valid(dense2_out_valid),
        .out_data(dense2_out_data),
        .out_c_idx(dense2_out_c_idx)
    );

    always @(posedge clk_int) begin
        if (!rst_n) begin
            state <= S_IDLE;
            in_idx <= 8'd0;
            in_valid <= 1'b0;
            in_data <= 32'sd0;
            done_reg <= 1'b0;
            logit0_reg <= 32'sd0;
            logit1_reg <= 32'sd0;
        end else begin
            case (state)
                S_IDLE: begin
                    in_idx <= 8'd0;
                    in_valid <= 1'b1;
                    in_data <= gap_mem[0];
                    done_reg <= 1'b0;
                    logit0_reg <= 32'sd0;
                    logit1_reg <= 32'sd0;
                    state <= S_RUN;
                end

                S_RUN: begin
                    if (in_valid) begin
                        if (in_idx == (GAP_COUNT - 1)) begin
                            in_valid <= 1'b0;
                            in_data <= 32'sd0;
                        end else begin
                            in_idx <= in_idx + 8'd1;
                            in_data <= gap_mem[in_idx + 8'd1];
                        end
                    end

                    if (dense2_out_valid) begin
                        if (dense2_out_c_idx == 0) begin
                            logit0_reg <= dense2_out_data;
                        end else if (dense2_out_c_idx == 1) begin
                            logit1_reg <= dense2_out_data;
                            done_reg <= 1'b1;
                            state <= S_DONE;
                        end
                    end
                end

                S_DONE: begin
                    in_valid <= 1'b0;
                    in_data <= 32'sd0;
                    state <= S_DONE;
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

    assign led_done = ~done_reg;
    assign led_class = ~(logit1_reg > logit0_reg);

endmodule
