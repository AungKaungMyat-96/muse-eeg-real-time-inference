`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Testbench: conv1d_tb
// Description:
//   Milestone 2 Conv1D verification harness.
//   - Loads input/weight/bias/expected files from absolute paths
//   - Verifies file counts
//   - Streams all 6000 input samples to DUT
//   - Compares DUT output on out_valid only
//   - Reports FIRST_MISMATCH and PASS/FAIL summary
//
// Notes:
//   - Simulation-only logic (file I/O)
//   - Matches current conv1d_int8 interface
// -----------------------------------------------------------------------------
module conv1d_tb;

    localparam DATA_W = 8;

    localparam L_IN = 3000;
    localparam C_IN = 2;
    localparam K = 7;
    localparam F_OUT = 16;

    localparam INPUT_COUNT = 6000;
    localparam WEIGHT_COUNT = 224;
    localparam BIAS_COUNT = 16;
    localparam OUTPUT_COUNT = 48000;

    reg clk;
    reg rst_n;
    reg in_valid;
    reg signed [DATA_W-1:0] in_data;

    wire out_valid;
    wire signed [31:0] out_data;
    wire [15:0] out_t_idx;
    wire [7:0] out_f_idx;

    reg signed [DATA_W-1:0] input_mem [0:INPUT_COUNT-1];
    reg signed [DATA_W-1:0] weight_mem [0:WEIGHT_COUNT-1];
    reg signed [31:0] bias_mem [0:BIAS_COUNT-1];
    reg signed [31:0] expected_mem [0:OUTPUT_COUNT-1];

    integer fd;
    integer code;
    integer temp_i;
    integer i;

    integer loaded_input_count;
    integer loaded_weight_count;
    integer loaded_bias_count;
    integer loaded_expected_count;

    integer compared_count;
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
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_data(in_data),
        .out_valid(out_valid),
        .out_data(out_data),
        .out_t_idx(out_t_idx),
        .out_f_idx(out_f_idx)
    );

    // 100 MHz equivalent clock (10 ns period)
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Output compare logic (compare only when out_valid is asserted)
    always @(posedge clk) begin
        if (rst_n && out_valid) begin
            if (compared_count < OUTPUT_COUNT) begin
                if ($signed(out_data) !== expected_mem[compared_count]) begin
                    mismatch_count <= mismatch_count + 1;
                    if (first_mismatch_reported == 0) begin
                        first_mismatch_reported <= 1;
                        $display("FIRST_MISMATCH idx=%0d rtl=%0d exp=%0d",
                                 compared_count, $signed(out_data), expected_mem[compared_count]);
                    end
                end
                compared_count <= compared_count + 1;
            end
        end
    end

    initial begin
        rst_n = 1'b0;
        in_valid = 1'b0;
        in_data = {DATA_W{1'b0}};

        loaded_input_count = 0;
        loaded_weight_count = 0;
        loaded_bias_count = 0;
        loaded_expected_count = 0;

        compared_count = 0;
        mismatch_count = 0;
        first_mismatch_reported = 0;

        for (i = 0; i < INPUT_COUNT; i = i + 1) begin
            input_mem[i] = 0;
        end
        for (i = 0; i < WEIGHT_COUNT; i = i + 1) begin
            weight_mem[i] = 0;
        end
        for (i = 0; i < BIAS_COUNT; i = i + 1) begin
            bias_mem[i] = 0;
        end
        for (i = 0; i < OUTPUT_COUNT; i = i + 1) begin
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

        fd = $fopen("D:/Users/Lenovo/project_1/muse_cnn_sources/weights/conv1d_w.mem", "r");
        if (fd == 0) begin
            $display("FAIL: cannot open conv1d_w.mem");
            $finish;
        end
        i = 0;
        while ((i < WEIGHT_COUNT) && (!$feof(fd))) begin
            code = $fscanf(fd, "%d\n", temp_i);
            if (code == 1) begin
                weight_mem[i] = temp_i[DATA_W-1:0];
                i = i + 1;
            end
        end
        $fclose(fd);
        loaded_weight_count = i;

        fd = $fopen("D:/Users/Lenovo/project_1/muse_cnn_sources/weights/conv1d_b.mem", "r");
        if (fd == 0) begin
            $display("FAIL: cannot open conv1d_b.mem");
            $finish;
        end
        i = 0;
        while ((i < BIAS_COUNT) && (!$feof(fd))) begin
            code = $fscanf(fd, "%d\n", temp_i);
            if (code == 1) begin
                bias_mem[i] = temp_i;
                i = i + 1;
            end
        end
        $fclose(fd);
        loaded_bias_count = i;

        fd = $fopen("D:/Users/Lenovo/project_1/muse_cnn_sources/data/conv1d_expected_int32.mem", "r");
        if (fd == 0) begin
            $display("FAIL: cannot open conv1d_expected_int32.mem");
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
        if (loaded_weight_count != WEIGHT_COUNT) begin
            $display("FAIL: weight count mismatch got=%0d expected=%0d", loaded_weight_count, WEIGHT_COUNT);
            $finish;
        end
        if (loaded_bias_count != BIAS_COUNT) begin
            $display("FAIL: bias count mismatch got=%0d expected=%0d", loaded_bias_count, BIAS_COUNT);
            $finish;
        end
        if (loaded_expected_count != OUTPUT_COUNT) begin
            $display("FAIL: expected count mismatch got=%0d expected=%0d", loaded_expected_count, OUTPUT_COUNT);
            $finish;
        end

        $display("Loaded counts OK: input=%0d weights=%0d bias=%0d expected=%0d",
                 loaded_input_count, loaded_weight_count, loaded_bias_count, loaded_expected_count);

        repeat (5) @(posedge clk);
        $display("INFO: Using Milestone 2 Conv1D INT32 DUT interface");
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

    // Completion and timeout control
    initial begin
        cycle_count = 0;
        timeout_cycles = 3000000;
        while (cycle_count < timeout_cycles) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;

            if (compared_count == OUTPUT_COUNT) begin
                if ((mismatch_count == 0) && (compared_count == OUTPUT_COUNT)) begin
                    $display("PASS: compared=%0d mismatches=%0d", compared_count, mismatch_count);
                end else begin
                    $display("FAIL: compared=%0d mismatches=%0d", compared_count, mismatch_count);
                end
                $finish;
            end
        end

        $display("FAIL: timeout before completion. compared=%0d mismatches=%0d",
                 compared_count, mismatch_count);
        $finish;
    end

endmodule
