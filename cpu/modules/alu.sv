// vim: set ft=systemverilog:

module alu #(
    parameter N = 32 // bit width
)(
    input [N-1:0] x,
    input [N-1:0] y,
    output reg [N-1:0] z,
    output reg zf,
    output reg sf
);
    always @(x or y) begin
        z = x + y;

        zf = (z == 0);
        sf = (z[N-1] == 1);
    end
endmodule
