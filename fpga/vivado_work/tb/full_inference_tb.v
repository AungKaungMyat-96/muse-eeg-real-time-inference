`timescale 1ns/1ps

module full_inference_tb;

    localparam DATA_W = 8;

    localparam INPUT_COUNT = 6000;
    localparam OUTPUT_COUNT = 2;

    localparam CONV1_EXPECT = 48000;
    localparam RELU1_EXPECT = 48000;
    localparam POOL1_EXPECT = 24000;
    localparam CONV2_EXPECT = 48000;
    localparam POOL2_EXPECT = 24000;
    localparam CONV3_EXPECT = 48000;
    localparam RELU3_EXPECT = 48000;
    localparam GAP_EXPECT = 64;
    localparam DENSE1_EXPECT = 32;
    localparam DENSE1_RELU_EXPECT = 32;
    localparam DENSE2_EXPECT = 2;

    reg clk;
    reg rst_n;
    reg in_valid;
    reg signed [DATA_W-1:0] in_data;

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

    reg signed [DATA_W-1:0] input_mem [0:INPUT_COUNT-1];
    reg signed [31:0] expected_mem [0:OUTPUT_COUNT-1];

    integer fd;
    integer code;
    integer temp_i;
    integer i;

    integer loaded_input_count;
    integer loaded_expected_count;

    integer conv1_count;
    integer relu1_count;
    integer pool1_count;
    integer conv2_count;
    integer pool2_count;
    integer conv3_count;
    integer relu3_count;
    integer gap_count;
    integer dense1_count;
    integer dense1_relu_count;
    integer dense2_count;

    integer full_inference_compared;
    integer mismatch_count;
    integer first_mismatch_reported;

    integer cycle_count;
    integer timeout_cycles;

    conv1d_int8 #(
        .DATA_W(8),
        .OUT_W(32),
        .L_IN(3000),
        .C_IN(2),
        .K(7),
        .F_OUT(16),
        .PAD_LEFT(3)
    ) u_conv1 (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_data(in_data),
        .out_valid(conv1_out_valid),
        .out_data(conv1_out_data),
        .out_t_idx(conv1_out_t_idx),
        .out_f_idx(conv1_out_f_idx)
    );

    relu_int32 u_relu1 (
        .clk(clk),
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
        .clk(clk),
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
        .clk(clk),
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
        .clk(clk),
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
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(pool2_out_valid),
        .in_data(pool2_out_data),
        .out_valid(conv3_out_valid),
        .out_data(conv3_out_data),
        .out_t_idx(conv3_out_t_idx),
        .out_f_idx(conv3_out_f_idx)
    );

    relu_int32 u_relu3 (
        .clk(clk),
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
        .clk(clk),
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
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(gap_out_valid),
        .in_data(gap_out_data),
        .out_valid(dense1_out_valid),
        .out_data(dense1_out_data),
        .out_o_idx(dense1_out_o_idx)
    );

    relu_int32 u_relu_dense1 (
        .clk(clk),
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
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(dense1_relu_out_valid),
        .in_data(dense1_relu_out_data),
        .out_valid(dense2_out_valid),
        .out_data(dense2_out_data),
        .out_c_idx(dense2_out_c_idx)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    always @(posedge clk) begin
        if (rst_n && conv1_out_valid) conv1_count <= conv1_count + 1;
        if (rst_n && relu1_out_valid) relu1_count <= relu1_count + 1;
        if (rst_n && pool1_out_valid) pool1_count <= pool1_count + 1;
        if (rst_n && conv2_out_valid) conv2_count <= conv2_count + 1;
        if (rst_n && pool2_out_valid) pool2_count <= pool2_count + 1;
        if (rst_n && conv3_out_valid) conv3_count <= conv3_count + 1;
        if (rst_n && relu3_out_valid) relu3_count <= relu3_count + 1;
        if (rst_n && gap_out_valid) gap_count <= gap_count + 1;
        if (rst_n && dense1_out_valid) dense1_count <= dense1_count + 1;
        if (rst_n && dense1_relu_out_valid) dense1_relu_count <= dense1_relu_count + 1;

        if (rst_n && dense2_out_valid) begin
            dense2_count <= dense2_count + 1;
            if (full_inference_compared < OUTPUT_COUNT) begin
                if ($signed(dense2_out_data) !== expected_mem[full_inference_compared]) begin
                    mismatch_count <= mismatch_count + 1;
                    if (first_mismatch_reported == 0) begin
                        first_mismatch_reported <= 1;
                        $display("FIRST_FULL_INFERENCE_MISMATCH idx=%0d c=%0d rtl=%0d expected=%0d",
                                 full_inference_compared,
                                 dense2_out_c_idx,
                                 $signed(dense2_out_data),
                                 expected_mem[full_inference_compared]);
                    end
                end
                full_inference_compared <= full_inference_compared + 1;
            end
        end
    end

    initial begin
        rst_n = 1'b0;
        in_valid = 1'b0;
        in_data = {DATA_W{1'b0}};

        loaded_input_count = 0;
        loaded_expected_count = 0;

        conv1_count = 0;
        relu1_count = 0;
        pool1_count = 0;
        conv2_count = 0;
        pool2_count = 0;
        conv3_count = 0;
        relu3_count = 0;
        gap_count = 0;
        dense1_count = 0;
        dense1_relu_count = 0;
        dense2_count = 0;

        full_inference_compared = 0;
        mismatch_count = 0;
        first_mismatch_reported = 0;

        for (i = 0; i < INPUT_COUNT; i = i + 1) begin
            input_mem[i] = 0;
        end
        for (i = 0; i < OUTPUT_COUNT; i = i + 1) begin
            expected_mem[i] = 0;
        end

        fd = $fopen("D:/Users/Lenovo/project_1/muse_cnn_sources/data/conv1d_input.mem", "r");
        if (fd == 0) begin
            $display("FAIL: cannot open conv1d_input.mem");
            $finish;
        end else begin
            i = 0;
            while ((i < INPUT_COUNT) && (!$feof(fd))) begin
                code = $fscanf(fd, "%d\n", temp_i);
                if (code == 1) begin
                    input_mem[i] = temp_i[DATA_W-1:0];
                    i = i + 1;
                end
            end
            $fclose(fd);
            loaded_input_count = i;
        end

        fd = $fopen("D:/Users/Lenovo/project_1/muse_cnn_sources/data/dense2_expected_int32.mem", "r");
        if (fd == 0) begin
            $display("FAIL: cannot open dense2_expected_int32.mem");
            $finish;
        end else begin
            i = 0;
            while ((i < OUTPUT_COUNT) && (!$feof(fd))) begin
                code = $fscanf(fd, "%d\n", temp_i);
                if (code == 1) begin
                    expected_mem[i] = temp_i;
                    i = i + 1;
                end
            end
            $fclose(fd);
            loaded_expected_count = i;
        end

        if (loaded_input_count != INPUT_COUNT) begin
            $display("FAIL: input count mismatch got=%0d expected=%0d", loaded_input_count, INPUT_COUNT);
            $finish;
        end
        if (loaded_expected_count != OUTPUT_COUNT) begin
            $display("FAIL: expected count mismatch got=%0d expected=%0d", loaded_expected_count, OUTPUT_COUNT);
            $finish;
        end

        $display("Loaded counts OK: input=%0d expected=%0d", loaded_input_count, loaded_expected_count);

        repeat (5) @(posedge clk);
        rst_n <= 1'b1;

        @(posedge clk);
        in_valid <= 1'b1;
        for (i = 0; i < INPUT_COUNT; i = i + 1) begin
            in_data <= input_mem[i];
            @(posedge clk);
        end
        in_valid <= 1'b0;
        in_data <= 8'sd0;
    end

    initial begin
        cycle_count = 0;
        timeout_cycles = 50000000;
        while (cycle_count < timeout_cycles) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;

            if (full_inference_compared == OUTPUT_COUNT) begin
                if ((mismatch_count == 0) &&
                    (conv1_count == CONV1_EXPECT) &&
                    (relu1_count == RELU1_EXPECT) &&
                    (pool1_count == POOL1_EXPECT) &&
                    (conv2_count == CONV2_EXPECT) &&
                    (pool2_count == POOL2_EXPECT) &&
                    (conv3_count == CONV3_EXPECT) &&
                    (relu3_count == RELU3_EXPECT) &&
                    (gap_count == GAP_EXPECT) &&
                    (dense1_count == DENSE1_EXPECT) &&
                    (dense1_relu_count == DENSE1_RELU_EXPECT) &&
                    (dense2_count == DENSE2_EXPECT)) begin
                    $display("PASS: full_inference_compared=2 mismatches=0");
                end else begin
                    $display("FAIL: full_inference_compared=%0d mismatches=%0d conv1_count=%0d relu1_count=%0d pool1_count=%0d conv2_count=%0d pool2_count=%0d conv3_count=%0d relu3_count=%0d gap_count=%0d dense1_count=%0d dense1_relu_count=%0d dense2_count=%0d",
                             full_inference_compared, mismatch_count,
                             conv1_count, relu1_count, pool1_count, conv2_count, pool2_count,
                             conv3_count, relu3_count, gap_count, dense1_count, dense1_relu_count, dense2_count);
                end
                $finish;
            end
        end

        $display("FAIL: timeout full_inference_compared=%0d mismatches=%0d conv1_count=%0d relu1_count=%0d pool1_count=%0d conv2_count=%0d pool2_count=%0d conv3_count=%0d relu3_count=%0d gap_count=%0d dense1_count=%0d dense1_relu_count=%0d dense2_count=%0d",
                 full_inference_compared, mismatch_count,
                 conv1_count, relu1_count, pool1_count, conv2_count, pool2_count,
                 conv3_count, relu3_count, gap_count, dense1_count, dense1_relu_count, dense2_count);
        $finish;
    end

endmodule
