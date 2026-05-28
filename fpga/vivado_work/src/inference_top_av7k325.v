`timescale 1ns/1ps

module inference_top_av7k325 (
    input  sys_clk_p,
    input  sys_clk_n,
    input  key1,
    output led_done,
    output led_class
);

    localparam INPUT_COUNT = 6000;

    localparam S_IDLE = 2'd0;
    localparam S_RUN  = 2'd1;
    localparam S_DONE = 2'd2;

    wire clk_int;
    wire rst_n;

    reg [1:0] state;
    reg [15:0] in_idx;
    reg in_valid;
    reg signed [7:0] in_data;

    reg done_reg;
    reg signed [31:0] logit0_reg;
    reg signed [31:0] logit1_reg;

    reg signed [7:0] input_mem [0:INPUT_COUNT-1];

    wire conv1_out_valid;
    wire signed [31:0] conv1_out_data;
    wire [15:0] conv1_out_t_idx;
    wire [7:0] conv1_out_f_idx;

    wire relu1_out_valid;
    wire signed [31:0] relu1_out_data;
    wire [15:0] relu1_out_t_idx;
    wire [7:0] relu1_out_f_idx;

    wire pool1_out_valid;
    wire signed [31:0] pool1_out_data;
    wire [15:0] pool1_out_t_pool_idx;
    wire [7:0] pool1_out_f_idx;

    wire conv2_out_valid;
    wire signed [31:0] conv2_out_data;
    wire [15:0] conv2_out_t_idx;
    wire [7:0] conv2_out_f_idx;

    wire pool2_out_valid;
    wire signed [31:0] pool2_out_data;
    wire [15:0] pool2_out_t_pool_idx;
    wire [7:0] pool2_out_f_idx;

    wire conv3_out_valid;
    wire signed [31:0] conv3_out_data;
    wire [15:0] conv3_out_t_idx;
    wire [7:0] conv3_out_f_idx;

    wire relu3_out_valid;
    wire signed [31:0] relu3_out_data;
    wire [15:0] relu3_out_t_idx;
    wire [7:0] relu3_out_f_idx;

    wire gap_out_valid;
    wire signed [31:0] gap_out_data;
    wire [7:0] gap_out_f_idx;

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

    // AV7K325 differential 200 MHz system clock
    IBUFDS u_ibufds_sysclk (
        .I(sys_clk_p),
        .IB(sys_clk_n),
        .O(clk_int)
    );

    // Fixed-sample preload memory using relative path for deployability.
    initial begin
        for (i = 0; i < INPUT_COUNT; i = i + 1) begin
            input_mem[i] = 8'sd0;
        end
        $readmemh("data/hex/conv1d_input_i8.hex", input_mem);
    end

    conv1d_int8 #(
        .DATA_W(8),
        .OUT_W(32),
        .L_IN(3000),
        .C_IN(2),
        .K(7),
        .F_OUT(16),
        .PAD_LEFT(3)
    ) u_conv1 (
        .clk(clk_int),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_data(in_data),
        .out_valid(conv1_out_valid),
        .out_data(conv1_out_data),
        .out_t_idx(conv1_out_t_idx),
        .out_f_idx(conv1_out_f_idx)
    );

    relu_int32 u_relu1 (
        .clk(clk_int),
        .rst_n(rst_n),
        .in_valid(conv1_out_valid),
        .in_data(conv1_out_data),
        .in_t_idx(conv1_out_t_idx),
        .in_f_idx(conv1_out_f_idx),
        .out_valid(relu1_out_valid),
        .out_data(relu1_out_data),
        .out_t_idx(relu1_out_t_idx),
        .out_f_idx(relu1_out_f_idx)
    );

    maxpool1d_int32 #(
        .F_OUT(16)
    ) u_pool1 (
        .clk(clk_int),
        .rst_n(rst_n),
        .in_valid(relu1_out_valid),
        .in_data(relu1_out_data),
        .in_t_idx(relu1_out_t_idx),
        .in_f_idx(relu1_out_f_idx),
        .out_valid(pool1_out_valid),
        .out_data(pool1_out_data),
        .out_t_pool_idx(pool1_out_t_pool_idx),
        .out_f_idx(pool1_out_f_idx)
    );

    conv2_int32 #(
        .IN_W(32),
        .W_W(8),
        .OUT_W(32),
        .L_IN(1500),
        .C_IN(16),
        .K(5),
        .F_OUT(32),
        .PAD_LEFT(2)
    ) u_conv2 (
        .clk(clk_int),
        .rst_n(rst_n),
        .in_valid(pool1_out_valid),
        .in_data(pool1_out_data),
        .out_valid(conv2_out_valid),
        .out_data(conv2_out_data),
        .out_t_idx(conv2_out_t_idx),
        .out_f_idx(conv2_out_f_idx)
    );

    maxpool2_int32 #(
        .F_OUT(32)
    ) u_pool2 (
        .clk(clk_int),
        .rst_n(rst_n),
        .in_valid(conv2_out_valid),
        .in_data(conv2_out_data),
        .in_t_idx(conv2_out_t_idx),
        .in_f_idx(conv2_out_f_idx),
        .out_valid(pool2_out_valid),
        .out_data(pool2_out_data),
        .out_t_pool_idx(pool2_out_t_pool_idx),
        .out_f_idx(pool2_out_f_idx)
    );

    conv3_int32 #(
        .IN_W(32),
        .W_W(8),
        .OUT_W(32),
        .L_IN(750),
        .C_IN(32),
        .K(3),
        .F_OUT(64),
        .PAD_LEFT(1)
    ) u_conv3 (
        .clk(clk_int),
        .rst_n(rst_n),
        .in_valid(pool2_out_valid),
        .in_data(pool2_out_data),
        .out_valid(conv3_out_valid),
        .out_data(conv3_out_data),
        .out_t_idx(conv3_out_t_idx),
        .out_f_idx(conv3_out_f_idx)
    );

    relu_int32 u_relu3 (
        .clk(clk_int),
        .rst_n(rst_n),
        .in_valid(conv3_out_valid),
        .in_data(conv3_out_data),
        .in_t_idx(conv3_out_t_idx),
        .in_f_idx(conv3_out_f_idx),
        .out_valid(relu3_out_valid),
        .out_data(relu3_out_data),
        .out_t_idx(relu3_out_t_idx),
        .out_f_idx(relu3_out_f_idx)
    );

    gap1d_int32 #(
        .L_IN(750),
        .F_OUT(64)
    ) u_gap (
        .clk(clk_int),
        .rst_n(rst_n),
        .in_valid(relu3_out_valid),
        .in_data(relu3_out_data),
        .out_valid(gap_out_valid),
        .out_data(gap_out_data),
        .out_f_idx(gap_out_f_idx)
    );

    dense1_int32 #(
        .IN_W(32),
        .W_W(8),
        .OUT_W(32),
        .IN_DIM(64),
        .OUT_DIM(32)
    ) u_dense1 (
        .clk(clk_int),
        .rst_n(rst_n),
        .in_valid(gap_out_valid),
        .in_data(gap_out_data),
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
            in_idx <= 16'd0;
            in_valid <= 1'b0;
            in_data <= 8'sd0;

            done_reg <= 1'b0;
            logit0_reg <= 32'sd0;
            logit1_reg <= 32'sd0;
        end else begin
            case (state)
                S_IDLE: begin
                    in_idx <= 16'd0;
                    in_valid <= 1'b1;
                    in_data <= input_mem[0];
                    done_reg <= 1'b0;
                    logit0_reg <= 32'sd0;
                    logit1_reg <= 32'sd0;
                    state <= S_RUN;
                end

                S_RUN: begin
                    if (in_valid) begin
                        if (in_idx == (INPUT_COUNT - 1)) begin
                            in_valid <= 1'b0;
                            in_data <= 8'sd0;
                        end else begin
                            in_idx <= in_idx + 16'd1;
                            in_data <= input_mem[in_idx + 16'd1];
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
                    in_data <= 8'sd0;
                    state <= S_DONE;
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

    // AV7K325 user LEDs are active-low.
    assign led_done = ~done_reg;
    assign led_class = ~(logit1_reg > logit0_reg);

endmodule
