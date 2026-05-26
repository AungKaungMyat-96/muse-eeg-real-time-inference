`timescale 1ns/1ps

module pool2_tb;

    localparam L_IN = 1500;
    localparam F_IN = 32;
    localparam L_OUT = 750;

    localparam INPUT_COUNT = 48000;
    localparam OUTPUT_COUNT = 24000;

    reg clk;
    reg rst_n;
    reg in_valid;
    reg signed [31:0] in_data;

    reg [15:0] in_t_idx;
    reg [7:0] in_f_idx;

    wire out_valid;
    wire signed [31:0] out_data;
    wire [15:0] out_t_pool_idx;
    wire [7:0] out_f_idx;

    reg signed [31:0] input_mem [0:INPUT_COUNT-1];
    reg signed [31:0] expected_mem [0:OUTPUT_COUNT-1];

    integer fd;
    integer code;
    integer temp_i;
    integer i;

    integer loaded_input_count;
    integer loaded_expected_count;

    integer pool2_compared;
    integer mismatch_count;
    integer first_mismatch_reported;

    integer cycle_count;
    integer timeout_cycles;

    maxpool2_int32 #(
        .F_OUT(32)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_data(in_data),
        .in_t_idx(in_t_idx),
        .in_f_idx(in_f_idx),
        .out_valid(out_valid),
        .out_data(out_data),
        .out_t_pool_idx(out_t_pool_idx),
        .out_f_idx(out_f_idx)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    always @(posedge clk) begin
        if (rst_n && out_valid) begin
            if (pool2_compared < OUTPUT_COUNT) begin
                if ($signed(out_data) !== expected_mem[pool2_compared]) begin
                    mismatch_count <= mismatch_count + 1;
                    if (first_mismatch_reported == 0) begin
                        first_mismatch_reported <= 1;
                        $display("FIRST_POOL2_MISMATCH idx=%0d t=%0d f=%0d rtl=%0d expected=%0d",
                                 pool2_compared,
                                 out_t_pool_idx,
                                 out_f_idx,
                                 $signed(out_data),
                                 expected_mem[pool2_compared]);
                    end
                end
                pool2_compared <= pool2_compared + 1;
            end
        end
    end

    initial begin
        rst_n = 1'b0;
        in_valid = 1'b0;
        in_data = 32'sd0;
        in_t_idx = 16'd0;
        in_f_idx = 8'd0;

        loaded_input_count = 0;
        loaded_expected_count = 0;

        pool2_compared = 0;
        mismatch_count = 0;
        first_mismatch_reported = 0;

        for (i = 0; i < INPUT_COUNT; i = i + 1) begin
            input_mem[i] = 0;
        end
        for (i = 0; i < OUTPUT_COUNT; i = i + 1) begin
            expected_mem[i] = 0;
        end

        fd = $fopen("D:/Users/Lenovo/project_1/muse_cnn_sources/data/conv2_expected_int32.mem", "r");
        if (fd == 0) begin
            $display("FAIL: cannot open conv2_expected_int32.mem");
            $finish;
        end
        i = 0;
        while ((i < INPUT_COUNT) && (!$feof(fd))) begin
            code = $fscanf(fd, "%d\n", temp_i);
            if (code == 1) begin
                input_mem[i] = temp_i;
                i = i + 1;
            end
        end
        $fclose(fd);
        loaded_input_count = i;

        fd = $fopen("D:/Users/Lenovo/project_1/muse_cnn_sources/data/pool2_expected_int32.mem", "r");
        if (fd == 0) begin
            $display("FAIL: cannot open pool2_expected_int32.mem");
            $finish;
        end
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
            in_t_idx <= i / F_IN;
            in_f_idx <= i % F_IN;
            @(posedge clk);
        end
        in_valid <= 1'b0;
        in_data <= 32'sd0;
        in_t_idx <= 16'd0;
        in_f_idx <= 8'd0;
    end

    initial begin
        cycle_count = 0;
        timeout_cycles = 5000000;
        while (cycle_count < timeout_cycles) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
            if (pool2_compared == OUTPUT_COUNT) begin
                if (mismatch_count == 0) begin
                    $display("PASS: pool2_compared=24000 mismatches=0");
                end else begin
                    $display("FAIL: pool2_compared=%0d mismatches=%0d", pool2_compared, mismatch_count);
                end
                $finish;
            end
        end

        $display("FAIL: timeout before pool2 completion. pool2_compared=%0d mismatches=%0d",
                 pool2_compared, mismatch_count);
        $finish;
    end

endmodule
