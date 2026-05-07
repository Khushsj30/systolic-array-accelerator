module pe (
    input  wire        clk,
    input  wire        rst,
    input  wire        en,
    input  wire [7:0]  a_in,
    input  wire [7:0]  b_in,
    output reg  [7:0]  a_out,
    output reg  [7:0]  b_out,
    output reg  [31:0] acc
);
    always @(posedge clk) begin
        if (rst) begin
            acc   <= 32'd0;
            a_out <= 8'd0;
            b_out <= 8'd0;
        end else if (en) begin
            acc   <= acc + (a_in * b_in);
            a_out <= a_in;
            b_out <= b_in;
        end
    end
endmodule