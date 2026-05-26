`timescale 1ns/1ps

module conv1_relu_pool_tb;

    localparam DATA_W = 8;
    localparam L_IN = 3000;
    localparam C_IN = 2;
    localparam F_OUT = 16;

    localparam INPUT_COUNT = 6000;
    localparam RELU_COUNT = 48000;
    localparam MAXPOOL_COUNT = 24000;

    reg clk;
    reg rst_n;
    reg in_valid;
    reg signed [DATA_W-1:0] in_data;

    wire conv_out_valid;
    wire signed [31:0] conv_out_data;
    wire [15:0] conv_out_t_idx;
    wire [7:0] conv_out_f_idx;

    wire relu_out_valid;
    wire signed [31:0] relu_out_data;
    wire [15:0] relu_out_t_idx;
    wire [7:0] relu_out_f_idx;

    wire pool_out_valid;
    wire signed [31:0] pool_out_data;
    wire [15:0] pool_out_t_pool_idx;
    wire [7:0] pool_out_f_idx;

    reg signed [DATA_W-1:0] input_mem [0:INPUT_COUNT-1];
    reg signed [31:0] relu_expected_mem [0:RELU_COUNT-1];
    reg signed [31:0] pool_expected_mem [0:MAXPOOL_COUNT-1];

    integer fd;
    integer code;
    integer temp_i;
    integer i;

    integer loaded_input_count;
    integer loaded_relu_expected_count;
    integer loaded_pool_expected_count;

    integer relu_compared_count;
    integer relu_mismatch_count;
    integer relu_first_mismatch_reported;

    integer pool_compared_count;
    integer pool_mismatch_count;
    integer pool_first_mismatch_reported;

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
        .out_valid(conv_out_valid),
        .out_data(conv_out_data),
        .out_t_idx(conv_out_t_idx),
        .out_f_idx(conv_out_f_idx)
    );

    relu_int32 u_relu1 (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(conv_out_valid),
        .in_data(conv_out_data),
        .in_t_idx(conv_out_t_idx),
        .in_f_idx(conv_out_f_idx),
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

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    always @(posedge clk) begin
        if (rst_n && relu_out_valid) begin
            if (relu_compared_count < RELU_COUNT) begin
                if ($signed(relu_out_data) !== relu_expected_mem[relu_compared_count]) begin
                    relu_mismatch_count <= relu_mismatch_count + 1;
                    if (relu_first_mismatch_reported == 0) begin
                        relu_first_mismatch_reported <= 1;
                        $display("FIRST_RELU_MISMATCH idx=%0d rtl=%0d exp=%0d t=%0d f=%0d",
                                 relu_compared_count,
                                 $signed(relu_out_data),
                                 relu_expected_mem[relu_compared_count],
                                 relu_out_t_idx,
                                 relu_out_f_idx);
                    end
                end
                relu_compared_count <= relu_compared_count + 1;
            end
        end

        if (rst_n && pool_out_valid) begin
            if (pool_compared_count < MAXPOOL_COUNT) begin
                if ($signed(pool_out_data) !== pool_expected_mem[pool_compared_count]) begin
                    pool_mismatch_count <= pool_mismatch_count + 1;
                    if (pool_first_mismatch_reported == 0) begin
                        pool_first_mismatch_reported <= 1;
                        $display("FIRST_MAXPOOL_MISMATCH idx=%0d rtl=%0d exp=%0d t_pool=%0d f=%0d",
                                 pool_compared_count,
                                 $signed(pool_out_data),
                                 pool_expected_mem[pool_compared_count],
                                 pool_out_t_pool_idx,
                                 pool_out_f_idx);
                    end
                end
                pool_compared_count <= pool_compared_count + 1;
            end
        end
    end

    initial begin
        rst_n = 1'b0;
        in_valid = 1'b0;
        in_data = {DATA_W{1'b0}};

        loaded_input_count = 0;
        loaded_relu_expected_count = 0;
        loaded_pool_expected_count = 0;

        relu_compared_count = 0;
        relu_mismatch_count = 0;
        relu_first_mismatch_reported = 0;

        pool_compared_count = 0;
        pool_mismatch_count = 0;
        pool_first_mismatch_reported = 0;

        for (i = 0; i < INPUT_COUNT; i = i + 1) begin
            input_mem[i] = 0;
        end
        for (i = 0; i < RELU_COUNT; i = i + 1) begin
            relu_expected_mem[i] = 0;
        end
        for (i = 0; i < MAXPOOL_COUNT; i = i + 1) begin
            pool_expected_mem[i] = 0;
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

        fd = $fopen("D:/Users/Lenovo/project_1/muse_cnn_sources/data/relu1_expected_int32.mem", "r");
        if (fd == 0) begin
            $display("FAIL: cannot open relu1_expected_int32.mem");
            $finish;
        end
        i = 0;
        while ((i < RELU_COUNT) && (!$feof(fd))) begin
            code = $fscanf(fd, "%d\n", temp_i);
            if (code == 1) begin
                relu_expected_mem[i] = temp_i;
                i = i + 1;
            end
        end
        $fclose(fd);
        loaded_relu_expected_count = i;

        fd = $fopen("D:/Users/Lenovo/project_1/muse_cnn_sources/data/maxpool1_expected_int32.mem", "r");
        if (fd == 0) begin
            $display("FAIL: cannot open maxpool1_expected_int32.mem");
            $finish;
        end
        i = 0;
        while ((i < MAXPOOL_COUNT) && (!$feof(fd))) begin
            code = $fscanf(fd, "%d\n", temp_i);
            if (code == 1) begin
                pool_expected_mem[i] = temp_i;
                i = i + 1;
            end
        end
        $fclose(fd);
        loaded_pool_expected_count = i;

        if (loaded_input_count != INPUT_COUNT) begin
            $display("FAIL: input count mismatch got=%0d expected=%0d", loaded_input_count, INPUT_COUNT);
            $finish;
        end
        if (loaded_relu_expected_count != RELU_COUNT) begin
            $display("FAIL: relu expected count mismatch got=%0d expected=%0d", loaded_relu_expected_count, RELU_COUNT);
            $finish;
        end
        if (loaded_pool_expected_count != MAXPOOL_COUNT) begin
            $display("FAIL: maxpool expected count mismatch got=%0d expected=%0d", loaded_pool_expected_count, MAXPOOL_COUNT);
            $finish;
        end

        $display("Loaded counts OK: input=%0d relu_expected=%0d maxpool_expected=%0d",
                 loaded_input_count, loaded_relu_expected_count, loaded_pool_expected_count);

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
        timeout_cycles = 3500000;
        while (cycle_count < timeout_cycles) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;

            if ((relu_compared_count == RELU_COUNT) && (pool_compared_count == MAXPOOL_COUNT)) begin
                if ((relu_mismatch_count == 0) && (pool_mismatch_count == 0)) begin
                    $display("PASS: relu_compared=%0d relu_mismatches=%0d maxpool_compared=%0d maxpool_mismatches=%0d",
                             relu_compared_count, relu_mismatch_count, pool_compared_count, pool_mismatch_count);
                end else begin
                    $display("FAIL: relu_compared=%0d relu_mismatches=%0d maxpool_compared=%0d maxpool_mismatches=%0d",
                             relu_compared_count, relu_mismatch_count, pool_compared_count, pool_mismatch_count);
                end
                $finish;
            end
        end

        $display("FAIL: timeout relu_compared=%0d/%0d maxpool_compared=%0d/%0d relu_mismatches=%0d maxpool_mismatches=%0d",
                 relu_compared_count, RELU_COUNT, pool_compared_count, MAXPOOL_COUNT,
                 relu_mismatch_count, pool_mismatch_count);
        $finish;
    end

endmodule
