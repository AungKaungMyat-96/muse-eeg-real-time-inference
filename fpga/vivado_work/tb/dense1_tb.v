`timescale 1ns/1ps

module dense1_tb;

    localparam INPUT_COUNT = 64;
    localparam OUTPUT_COUNT = 32;

    reg clk;
    reg rst_n;
    reg in_valid;
    reg signed [31:0] in_data;

    wire out_valid;
    wire signed [31:0] out_data;
    wire [7:0] out_o_idx;

    reg signed [31:0] input_mem [0:INPUT_COUNT-1];
    reg signed [31:0] expected_mem [0:OUTPUT_COUNT-1];

    integer fd;
    integer code;
    integer temp_i;
    integer i;

    integer loaded_input_count;
    integer loaded_expected_count;

    integer dense1_compared;
    integer mismatch_count;
    integer first_mismatch_reported;

    integer cycle_count;
    integer timeout_cycles;

    dense1_int32 #(
        .IN_W(32),
        .W_W(8),
        .OUT_W(32),
        .IN_DIM(64),
        .OUT_DIM(32)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_data(in_data),
        .out_valid(out_valid),
        .out_data(out_data),
        .out_o_idx(out_o_idx)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    always @(posedge clk) begin
        if (rst_n && out_valid) begin
            if (dense1_compared < OUTPUT_COUNT) begin
                if ($signed(out_data) !== expected_mem[dense1_compared]) begin
                    mismatch_count <= mismatch_count + 1;
                    if (first_mismatch_reported == 0) begin
                        first_mismatch_reported <= 1;
                        $display("FIRST_DENSE1_MISMATCH idx=%0d o=%0d rtl=%0d expected=%0d",
                                 dense1_compared,
                                 out_o_idx,
                                 $signed(out_data),
                                 expected_mem[dense1_compared]);
                    end
                end
                dense1_compared <= dense1_compared + 1;
            end
        end
    end

    initial begin
        rst_n = 1'b0;
        in_valid = 1'b0;
        in_data = 32'sd0;

        loaded_input_count = 0;
        loaded_expected_count = 0;

        dense1_compared = 0;
        mismatch_count = 0;
        first_mismatch_reported = 0;

        for (i = 0; i < INPUT_COUNT; i = i + 1) begin
            input_mem[i] = 0;
        end
        for (i = 0; i < OUTPUT_COUNT; i = i + 1) begin
            expected_mem[i] = 0;
        end

        fd = $fopen("D:/Users/Lenovo/project_1/muse_cnn_sources/data/dense1_input.mem", "r");
        if (fd == 0) begin
            $display("FAIL: cannot open dense1_input.mem");
            $finish;
        end else begin
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
        end

        fd = $fopen("D:/Users/Lenovo/project_1/muse_cnn_sources/data/dense1_expected_int32.mem", "r");
        if (fd == 0) begin
            $display("FAIL: cannot open dense1_expected_int32.mem");
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
        in_data <= 32'sd0;
    end

    initial begin
        cycle_count = 0;
        timeout_cycles = 1000000;
        while (cycle_count < timeout_cycles) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
            if (dense1_compared == OUTPUT_COUNT) begin
                if (mismatch_count == 0) begin
                    $display("PASS: dense1_compared=32 mismatches=0");
                end else begin
                    $display("FAIL: dense1_compared=%0d mismatches=%0d", dense1_compared, mismatch_count);
                end
                $finish;
            end
        end

        $display("FAIL: timeout before dense1 completion. dense1_compared=%0d mismatches=%0d",
                 dense1_compared, mismatch_count);
        $finish;
    end

endmodule
