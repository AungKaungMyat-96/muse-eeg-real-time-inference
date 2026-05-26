`timescale 1ns/1ps

module conv1_pool1_conv2_pool2_conv3_tb;

    localparam DATA_W = 8;

    localparam INPUT_COUNT = 6000;
    localparam CONV1_COUNT = 48000;
    localparam RELU1_COUNT = 48000;
    localparam POOL1_COUNT = 24000;
    localparam CONV2_COUNT = 48000;
    localparam POOL2_COUNT = 24000;
    localparam CONV3_COUNT = 48000;

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

    reg signed [DATA_W-1:0] input_mem [0:INPUT_COUNT-1];
    reg signed [31:0] expected_mem [0:CONV3_COUNT-1];

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
    integer integrated_conv3_compared;

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

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    always @(posedge clk) begin
        if (rst_n && conv1_out_valid) begin
            conv1_count <= conv1_count + 1;
        end
        if (rst_n && relu1_out_valid) begin
            relu1_count <= relu1_count + 1;
        end
        if (rst_n && pool1_out_valid) begin
            pool1_count <= pool1_count + 1;
        end
        if (rst_n && conv2_out_valid) begin
            conv2_count <= conv2_count + 1;
        end
        if (rst_n && pool2_out_valid) begin
            pool2_count <= pool2_count + 1;
        end

        if (rst_n && conv3_out_valid) begin
            if (integrated_conv3_compared < CONV3_COUNT) begin
                if ($signed(conv3_out_data) !== expected_mem[integrated_conv3_compared]) begin
                    mismatch_count <= mismatch_count + 1;
                    if (first_mismatch_reported == 0) begin
                        first_mismatch_reported <= 1;
                        $display("FIRST_INTEGRATED_CONV3_MISMATCH idx=%0d t=%0d f=%0d rtl=%0d expected=%0d",
                                 integrated_conv3_compared,
                                 conv3_out_t_idx,
                                 conv3_out_f_idx,
                                 $signed(conv3_out_data),
                                 expected_mem[integrated_conv3_compared]);
                    end
                end
                integrated_conv3_compared <= integrated_conv3_compared + 1;
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
        integrated_conv3_compared = 0;
        mismatch_count = 0;
        first_mismatch_reported = 0;

        for (i = 0; i < INPUT_COUNT; i = i + 1) begin
            input_mem[i] = 0;
        end
        for (i = 0; i < CONV3_COUNT; i = i + 1) begin
            expected_mem[i] = 0;
        end

        fd = $fopen("D:/Users/Lenovo/project_1/muse_cnn_sources/data/conv1d_input.mem", "r");
        if (fd == 0) begin
            $display("FAIL: cannot open conv1d_input.mem");
            $finish;
        end
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

        fd = $fopen("D:/Users/Lenovo/project_1/muse_cnn_sources/data/conv3_expected_int32.mem", "r");
        if (fd == 0) begin
            $display("FAIL: cannot open conv3_expected_int32.mem");
            $finish;
        end
        i = 0;
        while ((i < CONV3_COUNT) && (!$feof(fd))) begin
            code = $fscanf(fd, "%d\n", temp_i);
            if (code == 1) begin
                expected_mem[i] = temp_i;
                i = i + 1;
            end
        end
        $fclose(fd);
        loaded_expected_count = i;

        if (loaded_input_count != INPUT_COUNT) begin
            $display("FAIL: input count mismatch got=%0d expected=%0d", loaded_input_count, INPUT_COUNT);
            $finish;
        end
        if (loaded_expected_count != CONV3_COUNT) begin
            $display("FAIL: expected count mismatch got=%0d expected=%0d", loaded_expected_count, CONV3_COUNT);
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
        timeout_cycles = 30000000;
        while (cycle_count < timeout_cycles) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;

            if (integrated_conv3_compared == CONV3_COUNT) begin
                if ((mismatch_count == 0) &&
                    (conv1_count == CONV1_COUNT) &&
                    (relu1_count == RELU1_COUNT) &&
                    (pool1_count == POOL1_COUNT) &&
                    (conv2_count == CONV2_COUNT) &&
                    (pool2_count == POOL2_COUNT)) begin
                    $display("PASS: integrated_conv3_compared=48000 mismatches=0");
                end else begin
                    $display("FAIL: integrated_conv3_compared=%0d mismatches=%0d conv1_count=%0d relu1_count=%0d pool1_count=%0d conv2_count=%0d pool2_count=%0d conv3_count=%0d",
                             integrated_conv3_compared, mismatch_count,
                             conv1_count, relu1_count, pool1_count, conv2_count, pool2_count,
                             integrated_conv3_compared);
                end
                $finish;
            end
        end

        $display("FAIL: timeout before integrated Conv3 completion");
        $display("FAIL: integrated_conv3_compared=%0d mismatches=%0d conv1_count=%0d relu1_count=%0d pool1_count=%0d conv2_count=%0d pool2_count=%0d conv3_count=%0d",
                 integrated_conv3_compared, mismatch_count,
                 conv1_count, relu1_count, pool1_count, conv2_count, pool2_count,
                 integrated_conv3_compared);
        $finish;
    end

endmodule
