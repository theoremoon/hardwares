// vim: set ft=systemverilog:

/*
* 0001 ADD
* 0010 SUB
* 0011 MUL
* 0100 DIV
* 0101 AND
* 0110 OR
* 0111 XOR
* 1000 NOR
* 1001 SLL
* 1010 SLR
* 1011 SLT
* 1100
* 1101 MFHI
* 1110 EQ
* 1111 NEQ
*/

// N-bit alu
//  this alu only support unsigned operation (all overflows are ignored)
module alu #(
    parameter N = 32 // bit width
)(
    input clk,
    input [N-1:0] x,
    input [N-1:0] y,
    input [3:0] mode,
    output reg [N-1:0] z
);
    reg [N-1:0] hi; // hi stores higher 32 bit of multiplication result and modulus
    always @(posedge clk) begin
        case (mode)
            4'b0001: begin z <= x + y; end
            4'b0010: begin z <= x - y; end
            4'b0011: begin {hi, z} <= x * y; end
            4'b0100: begin z <= x / y; hi <= x % y; end
            4'b0101: begin z <= x & y; end
            4'b0110: begin z <= x | y; end
            4'b0111: begin z <= x ^ y; end
            4'b1000: begin z <= x ~| y; end      // NOR
            4'b1001: begin z <= x << y; end
            4'b1010: begin z <= x >> y; end
            4'b1011: begin z <= x < y; end
            4'b1101: begin z <= hi; end      // MFHI
            4'b1110: begin z <= x == y; end
            4'b1111: begin z <= x != y; end
        endcase
    end
endmodule
