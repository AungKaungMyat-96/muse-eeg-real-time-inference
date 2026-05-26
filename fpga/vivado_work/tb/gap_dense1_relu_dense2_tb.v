`timescale 1ns/1ps

module gap_dense1_relu_dense2_tb;

    localparam INPUT_COUNT = 64;
    localparam OUTPUT_COUNT = 2;

    reg clk;
    reg rst_n;
    reg in_valid;
    reg signed [31:0] in_data;

    wire dense1_out_valid;
    wire signed [31:0] dense1_out_data;
    wire [7:0] dense1_out_o_idx;

    wire relu_out_valid;
    wire signed [31:0] relu_out_data;
    wire [15:0] relu_out_t_idx;
    wire [7:0] relu_out_f_idx;

    wire dense2_out_valid;
    wire signed [31:0] dense2_out_data;
    wire [7:0] dense2_out_c_idx;

    reg signed [31:0] input_mem [0:INPUT_COUNT-1];
    reg signed [31:0] expected_mem [0:OUTPUT_COUNT-1];

    integer fd;
    integer code;
    integer temp_i;
    integer i;

    integer loaded_input_count;
    integer loaded_expected_count;

    integer dense1_count;
    integer relu_count;
    integer dense2_count;

    integer classifier_compared;
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
    ) u_dense1 (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_data(in_data),
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
        .out_valid(relu_out_valid),
        .out_data(relu_out_data),
        .out_t_idx(relu_out_t_idx),
        .out_f_idx(relu_out_f_idx)
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
        .in_valid(relu_out_valid),
        .in_data(relu_out_data),
        .out_valid(dense2_out_valid),
        .out_data(dense2_out_data),
        .out_c_idx(dense2_out_c_idx)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    always @(posedge clk) begin
        if (rst_n && dense1_out_valid) begin
            dense1_count <= dense1_count + 1;
        end
        if (rst_n && relu_out_valid) begin
            relu_count <= relu_count + 1;
        end
        if (rst_n && dense2_out_valid) begin
            dense2_count <= dense2_count + 1;
            if (classifier_compared < OUTPUT_COUNT) begin
                if ($signed(dense2_out_data) !== expected_mem[classifier_compared]) begin
                    mismatch_count <= mismatch_count + 1;
                    if (first_mismatch_reported == 0) begin
                        first_mismatch_reported <= 1;
                        $display("FIRST_CLASSIFIER_MISMATCH idx=%0d c=%0d rtl=%0d expected=%0d",
                                 classifier_compared,
                                 dense2_out_c_idx,
                                 $signed(dense2_out_data),
                                 expected_mem[classifier_compared]);
                    end
                end
                classifier_compared <= classifier_compared + 1;
            end
        end
    end

    initial begin
        rst_n = 1'b0;
        in_valid = 1'b0;
        in_data = 32'sd0;

        loaded_input_count = 0;
        loaded_expected_count = 0;

        dense1_count = 0;
        relu_count = 0;
        dense2_count = 0;

        classifier_compared = 0;
        mismatch_count = 0;
        first_mismatch_reported = 0;

        for (i = 0; i < INPUT_COUNT; i = i + 1) begin
            input_mem[i] = 0;
        end
        for (i = 0; i < OUTPUT_COUNT; i = i + 1) begin
            expected_mem[i] = 0;
        end

        fd = $fopen("D:/Users/Lenovo/project_1/muse_cnn_sources/data/gap_expected_int32.mem", "r");
        if (fd == 0) begin
            $display("FAIL: cannot open gap_expected_int32.mem");
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
        in_data <= 32'sd0;
    end

    initial begin
        cycle_count = 0;
        timeout_cycles = 1000000;
        while (cycle_count < timeout_cycles) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;

            if (classifier_compared == OUTPUT_COUNT) begin
                if ((mismatch_count == 0) &&
                    (dense1_count == 32) &&
                    (relu_count == 32) &&
                    (dense2_count == 2)) begin
                    $display("PASS: classifier_compared=2 mismatches=0");
                end else begin
                    $display("FAIL: classifier_compared=%0d mismatches=%0d dense1_count=%0d relu_count=%0d dense2_count=%0d",
                             classifier_compared, mismatch_count, dense1_count, relu_count, dense2_count);
                end
                $finish;
            end
        end

        $display("FAIL: timeout classifier_compared=%0d mismatches=%0d dense1_count=%0d relu_count=%0d dense2_count=%0d",
                 classifier_compared, mismatch_count, dense1_count, relu_count, dense2_count);
        $finish;
    end

endmodule
