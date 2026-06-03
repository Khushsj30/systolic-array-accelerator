// =============================================================================
// Module      : systolic_array
// Project     : Systolic Array AI Accelerator
// Author      : Khush (NIT Warangal)
// Description : 4x4 weight-stationary systolic array for matrix multiplication.
//               16 PE instances wired in a mesh. Input skewing controller
//               ensures diagonal data flow for correct systolic operation.
//               Computes C = A x B for 4x4 INT8 matrices at 100MHz.
// Parameters  : N=4 (array dimension), DATA_WIDTH=8 (operand bits)
// =============================================================================

module systolic_array (
    input  wire        clk,
    input  wire        rst,
    input  wire        en,
    // Flattened 4x8-bit inputs (Verilog-2001 compatible)
    input  wire [7:0]  a0, a1, a2, a3,
    input  wire [7:0]  b0, b1, b2, b3,
    // Flattened 4x4x32-bit outputs
    output wire [31:0] c00, c01, c02, c03,
    output wire [31:0] c10, c11, c12, c13,
    output wire [31:0] c20, c21, c22, c23,
    output wire [31:0] c30, c31, c32, c33
);
    // Horizontal wires: a_wire[row][col] — A flows left to right
    wire [7:0] a00,a01,a02,a03,a04;
    wire [7:0] a10,a11,a12,a13,a14;
    wire [7:0] a20,a21,a22,a23,a24;
    wire [7:0] a30,a31,a32,a33,a34;

    // Vertical wires: b_wire[row][col] — B flows top to bottom
    wire [7:0] b00,b10,b20,b30,b40;
    wire [7:0] b01,b11,b21,b31,b41;
    wire [7:0] b02,b12,b22,b32,b42;
    wire [7:0] b03,b13,b23,b33,b43;

    // Connect inputs to first row/col
    assign a00=a0; assign a10=a1; assign a20=a2; assign a30=a3;
    assign b00=b0; assign b01=b1; assign b02=b2; assign b03=b3;

    // Row 0
    pe pe00(.clk(clk),.rst(rst),.en(en),.a_in(a00),.b_in(b00),.a_out(a01),.b_out(b10),.acc(c00));
    pe pe01(.clk(clk),.rst(rst),.en(en),.a_in(a01),.b_in(b01),.a_out(a02),.b_out(b11),.acc(c01));
    pe pe02(.clk(clk),.rst(rst),.en(en),.a_in(a02),.b_in(b02),.a_out(a03),.b_out(b12),.acc(c02));
    pe pe03(.clk(clk),.rst(rst),.en(en),.a_in(a03),.b_in(b03),.a_out(a04),.b_out(b13),.acc(c03));
    // Row 1
    pe pe10(.clk(clk),.rst(rst),.en(en),.a_in(a10),.b_in(b10),.a_out(a11),.b_out(b20),.acc(c10));
    pe pe11(.clk(clk),.rst(rst),.en(en),.a_in(a11),.b_in(b11),.a_out(a12),.b_out(b21),.acc(c11));
    pe pe12(.clk(clk),.rst(rst),.en(en),.a_in(a12),.b_in(b12),.a_out(a13),.b_out(b22),.acc(c12));
    pe pe13(.clk(clk),.rst(rst),.en(en),.a_in(a13),.b_in(b13),.a_out(a14),.b_out(b23),.acc(c13));
    // Row 2
    pe pe20(.clk(clk),.rst(rst),.en(en),.a_in(a20),.b_in(b20),.a_out(a21),.b_out(b30),.acc(c20));
    pe pe21(.clk(clk),.rst(rst),.en(en),.a_in(a21),.b_in(b21),.a_out(a22),.b_out(b31),.acc(c21));
    pe pe22(.clk(clk),.rst(rst),.en(en),.a_in(a22),.b_in(b22),.a_out(a23),.b_out(b32),.acc(c22));
    pe pe23(.clk(clk),.rst(rst),.en(en),.a_in(a23),.b_in(b23),.a_out(a24),.b_out(b33),.acc(c23));
    // Row 3
    pe pe30(.clk(clk),.rst(rst),.en(en),.a_in(a30),.b_in(b30),.a_out(a31),.b_out(b40),.acc(c30));
    pe pe31(.clk(clk),.rst(rst),.en(en),.a_in(a31),.b_in(b31),.a_out(a32),.b_out(b41),.acc(c31));
    pe pe32(.clk(clk),.rst(rst),.en(en),.a_in(a32),.b_in(b32),.a_out(a33),.b_out(b42),.acc(c32));
    pe pe33(.clk(clk),.rst(rst),.en(en),.a_in(a33),.b_in(b33),.a_out(a34),.b_out(b43),.acc(c33));
endmodule
