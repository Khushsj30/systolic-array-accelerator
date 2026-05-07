`timescale 1ns/1ps
module systolic_array_tb;
    reg clk, rst, en;
    reg [7:0] a0,a1,a2,a3;
    reg [7:0] b0,b1,b2,b3;
    wire [31:0] c00,c01,c02,c03;
    wire [31:0] c10,c11,c12,c13;
    wire [31:0] c20,c21,c22,c23;
    wire [31:0] c30,c31,c32,c33;

    systolic_array dut(
        .clk(clk),.rst(rst),.en(en),
        .a0(a0),.a1(a1),.a2(a2),.a3(a3),
        .b0(b0),.b1(b1),.b2(b2),.b3(b3),
        .c00(c00),.c01(c01),.c02(c02),.c03(c03),
        .c10(c10),.c11(c11),.c12(c12),.c13(c13),
        .c20(c20),.c21(c21),.c22(c22),.c23(c23),
        .c30(c30),.c31(c31),.c32(c32),.c33(c33)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    reg [7:0] A [0:3][0:3];
    reg [7:0] B [0:3][0:3];
    integer t, pass_count=0, fail_count=0;

    task check32;
        input [31:0] got, exp;
        input integer ri, ci;
        begin
            if (got===exp) begin
                $display("  C[%0d][%0d] PASS: %0d", ri, ci, got);
                pass_count=pass_count+1;
            end else begin
                $display("  C[%0d][%0d] FAIL: got=%0d exp=%0d", ri, ci, got, exp);
                fail_count=fail_count+1;
            end
        end
    endtask

    initial begin
        $dumpfile("sim/vcd/array_tb.vcd");
        $dumpvars(0, systolic_array_tb);

        // Matrix A — same as Python golden reference
        A[0][0]=102; A[0][1]=179; A[0][2]=92;  A[0][3]=14;
        A[1][0]=106; A[1][1]=71;  A[1][2]=188; A[1][3]=20;
        A[2][0]=102; A[2][1]=121; A[2][2]=210; A[2][3]=214;
        A[3][0]=74;  A[3][1]=202; A[3][2]=87;  A[3][3]=116;

        // Matrix B — same as Python golden reference
        B[0][0]=99;  B[0][1]=103; B[0][2]=151; B[0][3]=130;
        B[1][0]=149; B[1][1]=52;  B[1][2]=1;   B[1][3]=87;
        B[2][0]=235; B[2][1]=157; B[2][2]=37;  B[2][3]=129;
        B[3][0]=191; B[3][1]=187; B[3][2]=20;  B[3][3]=160;

        rst=1; en=0;
        a0=0;a1=0;a2=0;a3=0;
        b0=0;b1=0;b2=0;b3=0;
        @(posedge clk); #1;
        rst=0; en=1;

        // Feed skewed inputs for 10 cycles (2N-1 + N-1 = 7+3 = enough)
        // A: row i is delayed by i cycles  → a_in[i] gets A[i][t-i] at cycle t
        // B: col j is delayed by j cycles  → b_in[j] gets B[t-j][j] at cycle t
        for (t=0; t<10; t=t+1) begin
            a0 = (t>=0 && t<=3) ? A[0][t]   : 0;
            a1 = (t>=1 && t<=4) ? A[1][t-1] : 0;
            a2 = (t>=2 && t<=5) ? A[2][t-2] : 0;
            a3 = (t>=3 && t<=6) ? A[3][t-3] : 0;

            b0 = (t>=0 && t<=3) ? B[t][0]   : 0;
            b1 = (t>=1 && t<=4) ? B[t-1][1] : 0;
            b2 = (t>=2 && t<=5) ? B[t-2][2] : 0;
            b3 = (t>=3 && t<=6) ? B[t-3][3] : 0;

            @(posedge clk); #1;
        end

        // Drain cycles — let last data ripple through all PEs
        a0=0;a1=0;a2=0;a3=0;
        b0=0;b1=0;b2=0;b3=0;
        repeat(8) @(posedge clk); #1;

        $display("=== ARRAY VERIFICATION vs GOLDEN REFERENCE ===");
        check32(c00,61063,0,0);  check32(c01,36876,0,1);  check32(c02,19265,0,2);  check32(c03,42941,0,3);
        check32(c10,69073,1,0);  check32(c11,47866,1,1);  check32(c12,23433,1,2);  check32(c13,47409,1,3);
        check32(c20,118351,2,0); check32(c21,89786,2,1);  check32(c22,27573,2,2);  check32(c23,85117,2,3);
        check32(c30,80025,3,0);  check32(c31,53477,3,1);  check32(c32,16915,3,2);  check32(c33,56977,3,3);

        $display("=== RESULTS: %0d/16 PASSED  %0d FAILED ===", pass_count, fail_count);
        $finish;
    end
endmodule