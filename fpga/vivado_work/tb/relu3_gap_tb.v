`timescale 1ns/1ps

module relu3_gap_tb;

    localparam INPUT_COUNT = 48000;
    localparam GAP_COUNT = 64;

    reg clk;
    reg rst_n;
    reg in_valid;
    reg signed [31:0] in_data;
    reg [15:0] in_t_idx;
    reg [7:0] in_f_idx;

    wire relu_out_valid;
    wire signed [31:0] relu_out_data;
    wire [15:0] relu_out_t_idx;
    wire [7:0] relu_out_f_idx;

    wire gap_out_valid;
    wire signed [31:0] gap_out_data;
    wire [7:0] gap_out_f_idx;

    reg signed [31:0] input_mem [0:INPUT_COUNT-1];
    reg signed [31:0] relu_expected_mem [0:INPUT_COUNT-1];
    reg signed [31:0] gap_expected_mem [0:GAP_COUNT-1];

    integer fd;
    integer code;
    integer temp_i;
    integer i;

    integer loaded_input_count;
    integer loaded_relu_expected_count;
    integer loaded_gap_expected_count;

    integer relu3_compared;
    integer relu3_mismatches;
    integer relu3_first_mismatch_reported;

    integer gap_compared;
    integer gap_mismatches;
    integer gap_first_mismatch_reported;

    integer cycle_count;
    integer timeout_cycles;

    relu_int32 u_relu3 (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_data(in_data),
        .in_t_idx(in_t_idx),
        .in_f_idx(in_f_idx),
        .out_valid(relu_out_valid),
        .out_data(relu_out_data),
        .out_t_idx(relu_out_t_idx),
        .out_f_idx(relu_out_f_idx)
    );

    gap1d_int32 #(
        .L_IN(750),
        .F_OUT(64)
    ) u_gap (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(relu_out_valid),
        .in_data(relu_out_data),
        .out_valid(gap_out_valid),
        .out_data(gap_out_data),
        .out_f_idx(gap_out_f_idx)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    always @(posedge clk) begin
        if (rst_n && relu_out_valid) begin
            if (relu3_compared < INPUT_COUNT) begin
                if ($signed(relu_out_data) !== relu_expected_mem[relu3_compared]) begin
                    relu3_mismatches <= relu3_mismatches + 1;
                    if (relu3_first_mismatch_reported == 0) begin
                        relu3_first_mismatch_reported <= 1;
                        $display("FIRST_RELU3_MISMATCH idx=%0d t=%0d f=%0d rtl=%0d expected=%0d",
                                 relu3_compared,
                                 relu_out_t_idx,
                                 relu_out_f_idx,
                                 $signed(relu_out_data),
                                 relu_expected_mem[relu3_compared]);
                    end
                end
                relu3_compared <= relu3_compared + 1;
            end
        end

        if (rst_n && gap_out_valid) begin
            if (gap_compared < GAP_COUNT) begin
                if ($signed(gap_out_data) !== gap_expected_mem[gap_compared]) begin
                    gap_mismatches <= gap_mismatches + 1;
                    if (gap_first_mismatch_reported == 0) begin
                        gap_first_mismatch_reported <= 1;
                        $display("FIRST_GAP_MISMATCH idx=%0d f=%0d rtl=%0d expected=%0d",
                                 gap_compared,
                                 gap_out_f_idx,
                                 $signed(gap_out_data),
                                 gap_expected_mem[gap_compared]);
                    end
                end
                gap_compared <= gap_compared + 1;
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
        loaded_relu_expected_count = 0;
        loaded_gap_expected_count = 0;

        relu3_compared = 0;
        relu3_mismatches = 0;
        relu3_first_mismatch_reported = 0;

        gap_compared = 0;
        gap_mismatches = 0;
        gap_first_mismatch_reported = 0;

        for (i = 0; i < INPUT_COUNT; i = i + 1) begin
            input_mem[i] = 0;
            relu_expected_mem[i] = 0;
        end
        for (i = 0; i < GAP_COUNT; i = i + 1) begin
            gap_expected_mem[i] = 0;
        end

        fd = $fopen("D:/Users/Lenovo/project_1/muse_cnn_sources/data/conv3_expected_int32.mem", "r");
        if (fd == 0) begin
            $display("FAIL: cannot open conv3_expected_int32.mem");
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

        fd = $fopen("D:/Users/Lenovo/project_1/muse_cnn_sources/data/relu3_expected_int32.mem", "r");
        if (fd == 0) begin
            $display("FAIL: cannot open relu3_expected_int32.mem");
            $finish;
        end
        i = 0;
        while ((i < INPUT_COUNT) && (!$feof(fd))) begin
            code = $fscanf(fd, "%d\n", temp_i);
            if (code == 1) begin
                relu_expected_mem[i] = temp_i;
                i = i + 1;
            end
        end
        $fclose(fd);
        loaded_relu_expected_count = i;

        fd = $fopen("D:/Users/Lenovo/project_1/muse_cnn_sources/data/gap_expected_int32.mem", "r");
        if (fd == 0) begin
            $display("FAIL: cannot open gap_expected_int32.mem");
            $finish;
        end
        i = 0;
        while ((i < GAP_COUNT) && (!$feof(fd))) begin
            code = $fscanf(fd, "%d\n", temp_i);
            if (code == 1) begin
                gap_expected_mem[i] = temp_i;
                i = i + 1;
            end
        end
        $fclose(fd);
        loaded_gap_expected_count = i;

        if (loaded_input_count != INPUT_COUNT) begin
            $display("FAIL: input count mismatch got=%0d expected=%0d", loaded_input_count, INPUT_COUNT);
            $finish;
        end
        if (loaded_relu_expected_count != INPUT_COUNT) begin
            $display("FAIL: relu expected count mismatch got=%0d expected=%0d", loaded_relu_expected_count, INPUT_COUNT);
            $finish;
        end
        if (loaded_gap_expected_count != GAP_COUNT) begin
            $display("FAIL: gap expected count mismatch got=%0d expected=%0d", loaded_gap_expected_count, GAP_COUNT);
            $finish;
        end

        $display("Loaded counts OK: input=%0d relu_expected=%0d gap_expected=%0d",
                 loaded_input_count, loaded_relu_expected_count, loaded_gap_expected_count);

        repeat (5) @(posedge clk);
        rst_n <= 1'b1;

        @(posedge clk);
        in_valid <= 1'b1;
        for (i = 0; i < INPUT_COUNT; i = i + 1) begin
            in_data <= input_mem[i];
            in_t_idx <= i / 64;
            in_f_idx <= i % 64;
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

            if ((relu3_compared == INPUT_COUNT) && (gap_compared == GAP_COUNT)) begin
                if ((relu3_mismatches == 0) && (gap_mismatches == 0)) begin
                    $display("PASS: relu3_compared=48000 relu3_mismatches=0 gap_compared=64 gap_mismatches=0");
                end else begin
                    $display("FAIL: relu3_compared=%0d relu3_mismatches=%0d gap_compared=%0d gap_mismatches=%0d",
                             relu3_compared, relu3_mismatches, gap_compared, gap_mismatches);
                end
                $finish;
            end
        end

        $display("FAIL: timeout relu3_compared=%0d/%0d gap_compared=%0d/%0d relu3_mismatches=%0d gap_mismatches=%0d",
                 relu3_compared, INPUT_COUNT, gap_compared, GAP_COUNT,
                 relu3_mismatches, gap_mismatches);
        $finish;
    end

endmodule
