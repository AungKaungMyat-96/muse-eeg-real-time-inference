`timescale 1ns/1ps

module conv1_relu_pool_conv2_tb;

    localparam DATA_W = 8;
    localparam L_IN = 3000;
    localparam C_IN = 2;
    localparam F_OUT = 16;

    localparam INPUT_COUNT = 6000;
    localparam RELU_COUNT = 48000;
    localparam POOL_COUNT = 24000;
    localparam CONV2_COUNT = 48000;

    reg clk;
    reg rst_n;
    reg in_valid;
    reg signed [DATA_W-1:0] in_data;

    wire conv1_out_valid;
    wire signed [31:0] conv1_out_data;
    wire [15:0] conv1_out_t_idx;
    wire [7:0] conv1_out_f_idx;

    wire relu_out_valid;
    wire signed [31:0] relu_out_data;
    wire [15:0] relu_out_t_idx;
    wire [7:0] relu_out_f_idx;

    wire pool_out_valid;
    wire signed [31:0] pool_out_data;
    wire [15:0] pool_out_t_pool_idx;
    wire [7:0] pool_out_f_idx;

    wire conv2_out_valid;
    wire signed [31:0] conv2_out_data;
    wire [15:0] conv2_out_t_idx;
    wire [7:0] conv2_out_f_idx;

    reg signed [DATA_W-1:0] input_mem [0:INPUT_COUNT-1];
    reg signed [31:0] expected_mem [0:CONV2_COUNT-1];

    integer fd;
    integer code;
    integer temp_i;
    integer i;

    integer loaded_input_count;
    integer loaded_expected_count;

    integer relu_count;
    integer pool_count;
    integer integrated_conv2_compared;
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
        .out_valid(relu_out_valid),
        .out_data(relu_out_data),
        .out_t_idx(relu_out_t_idx),
        .out_f_idx(relu_out_f_idx)
    );

    maxpool1d_int32 #(
        .F_OUT(16)
    ) u_pool1 (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(relu_out_valid),
        .in_data(relu_out_data),
        .in_t_idx(relu_out_t_idx),
        .in_f_idx(relu_out_f_idx),
        .out_valid(pool_out_valid),
        .out_data(pool_out_data),
        .out_t_pool_idx(pool_out_t_pool_idx),
        .out_f_idx(pool_out_f_idx)
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
        .in_valid(pool_out_valid),
        .in_data(pool_out_data),
        .out_valid(conv2_out_valid),
        .out_data(conv2_out_data),
        .out_t_idx(conv2_out_t_idx),
        .out_f_idx(conv2_out_f_idx)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    always @(posedge clk) begin
        if (rst_n && relu_out_valid) begin
            relu_count <= relu_count + 1;
        end

        if (rst_n && pool_out_valid) begin
            pool_count <= pool_count + 1;
        end

        if (rst_n && conv2_out_valid) begin
            if (integrated_conv2_compared < CONV2_COUNT) begin
                if ($signed(conv2_out_data) !== expected_mem[integrated_conv2_compared]) begin
                    mismatch_count <= mismatch_count + 1;
                    if (first_mismatch_reported == 0) begin
                        first_mismatch_reported <= 1;
                        $display("FIRST_INTEGRATED_CONV2_MISMATCH idx=%0d t=%0d f=%0d rtl=%0d expected=%0d",
                                 integrated_conv2_compared,
                                 conv2_out_t_idx,
                                 conv2_out_f_idx,
                                 $signed(conv2_out_data),
                                 expected_mem[integrated_conv2_compared]);
                    end
                end
                integrated_conv2_compared <= integrated_conv2_compared + 1;
            end
        end
    end

    initial begin
        rst_n = 1'b0;
        in_valid = 1'b0;
        in_data = {DATA_W{1'b0}};

        loaded_input_count = 0;
        loaded_expected_count = 0;

        relu_count = 0;
        pool_count = 0;
        integrated_conv2_compared = 0;
        mismatch_count = 0;
        first_mismatch_reported = 0;

        for (i = 0; i < INPUT_COUNT; i = i + 1) begin
            input_mem[i] = 0;
        end
        for (i = 0; i < CONV2_COUNT; i = i + 1) begin
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

        fd = $fopen("D:/Users/Lenovo/project_1/muse_cnn_sources/data/conv2_expected_int32.mem", "r");
        if (fd == 0) begin
            $display("FAIL: cannot open conv2_expected_int32.mem");
            $finish;
        end
        i = 0;
        while ((i < CONV2_COUNT) && (!$feof(fd))) begin
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
        if (loaded_expected_count != CONV2_COUNT) begin
            $display("FAIL: expected count mismatch got=%0d expected=%0d", loaded_expected_count, CONV2_COUNT);
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
        timeout_cycles = 20000000;
        while (cycle_count < timeout_cycles) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;

            if (integrated_conv2_compared == CONV2_COUNT) begin
                if ((mismatch_count == 0) &&
                    (relu_count == RELU_COUNT) &&
                    (pool_count == POOL_COUNT)) begin
                    $display("PASS: integrated_conv2_compared=48000 mismatches=0");
                end else begin
                    $display("FAIL: integrated_conv2_compared=%0d mismatches=%0d relu_count=%0d pool_count=%0d",
                             integrated_conv2_compared, mismatch_count, relu_count, pool_count);
                end
                $finish;
            end
        end

        $display("FAIL: timeout before integrated Conv2 completion");
        $display("FAIL: integrated_conv2_compared=%0d mismatches=%0d relu_count=%0d pool_count=%0d",
                 integrated_conv2_compared, mismatch_count, relu_count, pool_count);
        $finish;
    end

endmodule
