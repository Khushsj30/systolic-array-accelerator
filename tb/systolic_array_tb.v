`timescale 1ns/1ps
module systolic_array_tb;

    // Parameters
    parameter N          = 4;
    parameter DATA_WIDTH = 8;
    parameter ACC_WIDTH  = 32;

    reg clk, rst, en;
    reg  [N*DATA_WIDTH-1:0] a_flat;
    reg  [N*DATA_WIDTH-1:0] b_flat;
    wire [N*N*ACC_WIDTH-1:0] c_flat;

    // DUT
    systolic_array #(.N(N), .DATA_WIDTH(DATA_WIDTH), .ACC_WIDTH(ACC_WIDTH)) dut (
        .clk(clk), .rst(rst), .en(en),
        .a_flat(a_flat), .b_flat(b_flat), .c_flat(c_flat)
    );

    // Helper to extract c[row][col] from flat output
    function [ACC_WIDTH-1:0] get_c;
        input integer row, col;
        begin
            get_c = c_flat[((row*N+col+1)*ACC_WIDTH-1) -: ACC_WIDTH];
        end
    endfunction

    initial clk = 0;
    always #5 clk = ~clk;

    reg [DATA_WIDTH-1:0] A [0:N-1][0:N-1];
    reg [DATA_WIDTH-1:0] B [0:N-1][0:N-1];
    reg [ACC_WIDTH-1:0]  expected [0:N-1][0:N-1];

    integer t, i, j, pass_count, fail_count, total_pass, total_fail;

    // Feed skewed inputs for one matrix multiply
    task feed_matrices;
        integer t, i, j;
        begin
            rst=0; en=1;
            for (t=0; t<10; t=t+1) begin
                // A: row i delayed by i cycles
                a_flat[1*DATA_WIDTH-1 -: DATA_WIDTH] = (t>=0 && t<N) ? A[0][t]   : 0;
                a_flat[2*DATA_WIDTH-1 -: DATA_WIDTH] = (t>=1 && t<N+1) ? A[1][t-1] : 0;
                a_flat[3*DATA_WIDTH-1 -: DATA_WIDTH] = (t>=2 && t<N+2) ? A[2][t-2] : 0;
                a_flat[4*DATA_WIDTH-1 -: DATA_WIDTH] = (t>=3 && t<N+3) ? A[3][t-3] : 0;
                // B: col j delayed by j cycles
                b_flat[1*DATA_WIDTH-1 -: DATA_WIDTH] = (t>=0 && t<N) ? B[t][0]   : 0;
                b_flat[2*DATA_WIDTH-1 -: DATA_WIDTH] = (t>=1 && t<N+1) ? B[t-1][1] : 0;
                b_flat[3*DATA_WIDTH-1 -: DATA_WIDTH] = (t>=2 && t<N+2) ? B[t-2][2] : 0;
                b_flat[4*DATA_WIDTH-1 -: DATA_WIDTH] = (t>=3 && t<N+3) ? B[t-3][3] : 0;
                @(posedge clk); #1;
            end
            // Drain
            a_flat=0; b_flat=0;
            repeat(8) @(posedge clk); #1;
        end
    endtask

    // Check all outputs against expected
    task check_all;
        input [127:0] test_name;
        integer i, j;
        begin
            $display("=== TEST: %s ===", test_name);
            for (i=0; i<N; i=i+1) begin
                for (j=0; j<N; j=j+1) begin
                    if (get_c(i,j) === expected[i][j]) begin
                        $display("  C[%0d][%0d] PASS: %0d", i, j, get_c(i,j));
                        pass_count = pass_count + 1;
                    end else begin
                        $display("  C[%0d][%0d] FAIL: got=%0d exp=%0d", i, j, get_c(i,j), expected[i][j]);
                        fail_count = fail_count + 1;
                    end
                end
            end
        end
    endtask

    // Reset DUT
    task do_reset;
        begin
            rst=1; en=0; a_flat=0; b_flat=0;
            @(posedge clk); #1;
            rst=0;
        end
    endtask

    integer k;

    initial begin
        $dumpfile("sim/vcd/array_tb.vcd");
        $dumpvars(0, systolic_array_tb);
        pass_count=0; fail_count=0;
        total_pass=0; total_fail=0;

        // =============================================
        // TEST 1 — Golden Reference Matrix
        // =============================================
        do_reset;
        A[0][0]=102; A[0][1]=179; A[0][2]=92;  A[0][3]=14;
        A[1][0]=106; A[1][1]=71;  A[1][2]=188; A[1][3]=20;
        A[2][0]=102; A[2][1]=121; A[2][2]=210; A[2][3]=214;
        A[3][0]=74;  A[3][1]=202; A[3][2]=87;  A[3][3]=116;

        B[0][0]=99;  B[0][1]=103; B[0][2]=151; B[0][3]=130;
        B[1][0]=149; B[1][1]=52;  B[1][2]=1;   B[1][3]=87;
        B[2][0]=235; B[2][1]=157; B[2][2]=37;  B[2][3]=129;
        B[3][0]=191; B[3][1]=187; B[3][2]=20;  B[3][3]=160;

        expected[0][0]=61063; expected[0][1]=36876; expected[0][2]=19265; expected[0][3]=42941;
        expected[1][0]=69073; expected[1][1]=47866; expected[1][2]=23433; expected[1][3]=47409;
        expected[2][0]=118351;expected[2][1]=89786; expected[2][2]=27573; expected[2][3]=85117;
        expected[3][0]=80025; expected[3][1]=53477; expected[3][2]=16915; expected[3][3]=56977;

        feed_matrices;
        check_all("GOLDEN REFERENCE");
        total_pass=total_pass+pass_count; total_fail=total_fail+fail_count;
        pass_count=0; fail_count=0;

        // =============================================
        // TEST 2 — All-Zeros (edge case)
        // =============================================
        do_reset;
        for (i=0; i<N; i=i+1)
            for (j=0; j<N; j=j+1) begin
                A[i][j]=0; B[i][j]=0; expected[i][j]=0;
            end
        feed_matrices;
        check_all("ALL ZEROS");
        total_pass=total_pass+pass_count; total_fail=total_fail+fail_count;
        pass_count=0; fail_count=0;

        // =============================================
        // TEST 3 — Identity Matrix (A x I = A)
        // =============================================
        do_reset;
        for (i=0; i<N; i=i+1)
            for (j=0; j<N; j=j+1) begin
                A[i][j] = i*4 + j + 1;   // 1..16
                B[i][j] = (i==j) ? 1 : 0; // identity
                expected[i][j] = A[i][j]; // A x I = A
            end
        feed_matrices;
        check_all("IDENTITY MATRIX (A x I = A)");
        total_pass=total_pass+pass_count; total_fail=total_fail+fail_count;
        pass_count=0; fail_count=0;

        // =============================================
        // TEST 4 — Max Value Stress (overflow boundary)
        // =============================================
        do_reset;
        for (i=0; i<N; i=i+1)
            for (j=0; j<N; j=j+1) begin
                A[i][j] = 8'hFF;  // 255
                B[i][j] = 8'hFF;  // 255
                // expected C[i][j] = sum of 4 x (255*255) = 4 x 65025 = 260100
                expected[i][j] = 32'd260100;
            end
        feed_matrices;
        check_all("MAX VALUE STRESS (255x255x4)");
        total_pass=total_pass+pass_count; total_fail=total_fail+fail_count;
        pass_count=0; fail_count=0;

        // =============================================
        // TEST 5 — Reset Mid-Computation
        // =============================================
        do_reset;
        $display("=== TEST: RESET MID-COMPUTATION ===");
        // Start feeding garbage data
        en=1;
        A[0][0]=99; A[0][1]=88; A[0][2]=77; A[0][3]=66;
        for (i=0; i<N; i=i+1)
            for (j=0; j<N; j=j+1) begin
                A[i][j]=99; B[i][j]=88;
            end
        // Feed 3 cycles then assert rst
        for (t=0; t<3; t=t+1) begin
            a_flat[1*DATA_WIDTH-1 -: DATA_WIDTH] = A[0][t];
            b_flat[1*DATA_WIDTH-1 -: DATA_WIDTH] = B[t][0];
            @(posedge clk); #1;
        end
        // Mid-computation reset — hold rst for 2 cycles, drain N more
        rst=1; en=0; a_flat=0; b_flat=0;
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst=0;
        repeat(4) @(posedge clk); #1;
        // After reset all outputs must be 0
        if (c_flat === 0) begin
            $display("  RESET MID-COMPUTATION PASS: all outputs cleared to 0");
            total_pass = total_pass + 1;
        end else begin
            $display("  RESET MID-COMPUTATION FAIL: outputs not zero after rst");
            total_fail = total_fail + 1;
        end

        // =============================================
        // TEST 6 — Back-to-Back (no reset between runs)
        // =============================================
        do_reset;
        $display("=== TEST: BACK-TO-BACK RUNS ===");
        // Run 1 — small matrix
        for (i=0; i<N; i=i+1)
            for (j=0; j<N; j=j+1) begin
                A[i][j]=1; B[i][j]=1;
                expected[i][j]=4; // 1x1 x 4 elements = 4
            end
        feed_matrices;
        pass_count=0; fail_count=0;
        check_all("BACK-TO-BACK RUN 1");
        // Run 2 — immediately after, different data
        do_reset;
        for (i=0; i<N; i=i+1)
            for (j=0; j<N; j=j+1) begin
                A[i][j]=2; B[i][j]=2;
                expected[i][j]=16; // 2x2 x 4 elements = 16
            end
        feed_matrices;
        check_all("BACK-TO-BACK RUN 2");
        total_pass=total_pass+pass_count; total_fail=total_fail+fail_count;

        // =============================================
        // FINAL RESULTS
        // =============================================
        $display("==========================================");
        $display("=== FINAL: %0d PASSED  %0d FAILED ===", total_pass, total_fail);
        $display("==========================================");
        $finish;
    end
endmodule
