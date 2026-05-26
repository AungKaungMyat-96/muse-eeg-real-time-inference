`timescale 1ns/1ps

module conv2_tb;

    localparam IN_W = 32;
    localparam L_IN = 1500;
    localparam C_IN = 16;
    localparam F_OUT = 32;

    localparam INPUT_COUNT = 24000;
    localparam OUTPUT_COUNT = 48000;

    reg clk;
    reg rst_n;
    reg in_valid;
    reg signed [IN_W-1:0] in_data;

    wire out_valid;
    wire signed [31:0] out_data;
    wire [15:0] out_t_idx;
    wire [7:0] out_f_idx;

    reg signed [IN_W-1:0] input_mem [0:INPUT_COUNT-1];
    reg signed [31:0] expected_mem [0:OUTPUT_COUNT-1];

    integer fd;
    integer code;
    integer temp_i;
    integer i;

    integer loaded_input_count;
    integer loaded_expected_count;

    integer compared_count;
    integer mismatch_count;
    integer first_mismatch_reported;

    integer cycle_count;
    integer timeout_cycles;

    conv2_int32 #(
        .IN_W(32),
        .W_W(8),
        .OUT_W(32),
        .L_IN(1500),
        .C_IN(16),
        .K(5),
        .F_OUT(32),
        .PAD_LEFT(2)
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

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    always @(posedge clk) begin
        if (rst_n && out_valid) begin
            if (compared_count < OUTPUT_COUNT) begin
                if ($signed(out_data) !== expected_mem[compared_count]) begin
                    mismatch_count <= mismatch_count + 1;
                    if (first_mismatch_reported == 0) begin
                        first_mismatch_reported <= 1;
                        $display("FIRST_MISMATCH idx=%0d t=%0d f=%0d rtl=%0d expected=%0d",
                                 compared_count,
                                 out_t_idx,
                                 out_f_idx,
                                 $signed(out_data),
                                 expected_mem[compared_count]);
                    end
                end
                compared_count <= compared_count + 1;
            end
        end
    end

    initial begin
        rst_n = 1'b0;
        in_valid = 1'b0;
        in_data = 32'sd0;

        loaded_input_count = 0;
        loaded_expected_count = 0;

        compared_count = 0;
        mismatch_count = 0;
        first_mismatch_reported = 0;

        for (i = 0; i < INPUT_COUNT; i = i + 1) begin
            input_mem[i] = 0;
        end
        for (i = 0; i < OUTPUT_COUNT; i = i + 1) begin
            expected_mem[i] = 0;
        end

        fd = $fopen("D:/Users/Lenovo/project_1/muse_cnn_sources/data/conv2_input.mem", "r");
        if (fd == 0) begin
            $display("FAIL: cannot open conv2_input.mem");
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

        fd = $fopen("D:/Users/Lenovo/project_1/muse_cnn_sources/data/conv2_expected_int32.mem", "r");
        if (fd == 0) begin
            $display("FAIL: cannot open conv2_expected_int32.mem");
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
            @(posedge clk);
        end
        in_valid <= 1'b0;
        in_data <= 32'sd0;
    end

    initial begin
        cycle_count = 0;
        timeout_cycles = 5000000;
        while (cycle_count < timeout_cycles) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
            if (compared_count == OUTPUT_COUNT) begin
                if (mismatch_count == 0) begin
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
