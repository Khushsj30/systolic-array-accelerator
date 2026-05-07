
`timescale 1ns/1ps
module pe_tb;
    reg clk, rst, en;
    reg [7:0] a_in, b_in;
    wire [7:0] a_out, b_out;
    wire [31:0] acc;

    pe dut (.clk(clk),.rst(rst),.en(en),.a_in(a_in),.b_in(b_in),.a_out(a_out),.b_out(b_out),.acc(acc));

    initial clk = 0;
    always #5 clk = ~clk;

    integer pass_count = 0;
    integer fail_count = 0;

    task check;
        input [31:0] got;
        input [31:0] expected;
        input [7:0]  test_num;
        begin
            if (got === expected) begin
                $display("  TEST %0d PASSED: acc=%0d (expected %0d)", test_num, got, expected);
                pass_count = pass_count + 1;
            end else begin
                $display("  TEST %0d FAILED: acc=%0d (expected %0d)", test_num, got, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("sim/vcd/pe_tb.vcd");
        $dumpvars(0, pe_tb);
        $display("=== PE TESTBENCH START ===");

        rst=1; en=0; a_in=0; b_in=0;
        @(posedge clk); #1;

        $display("[TEST 1] Reset");
        check(acc, 32'h0, 1);

        rst=0; en=1; a_in=8'd3; b_in=8'd4;
        $display("[TEST 2] 3x4=12");
        @(posedge clk); #1;
        check(acc, 32'd12, 2);

        a_in=8'd5; b_in=8'd6;
        $display("[TEST 3] 12+(5x6)=42");
        @(posedge clk); #1;
        check(acc, 32'd42, 3);

        en=0; a_in=8'd99; b_in=8'd99;
        $display("[TEST 4] Enable gate: acc stays 42");
        @(posedge clk); #1;
        check(acc, 32'd42, 4);

        en=1; a_in=8'd255; b_in=8'd255;
        rst=1; @(posedge clk); #1; rst=0;
        @(posedge clk); #1;
        $display("[TEST 5] 255x255=65025");
        check(acc, 32'd65025, 5);

        $display("=== RESULTS: %0d PASSED %0d FAILED ===", pass_count, fail_count);
        $finish;
    end
endmodule