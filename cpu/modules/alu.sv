// vim: set ft=systemverilog:

module alu #(
    parameter N = 32 // bit width
)(
    input [N-1:0] x,
    input [N-1:0] y,
    output reg [N-1:0] z,
    output reg zf
);
    always @(x or y) begin
        z = x + y;

        if (z == 0) begin
            zf = 1;
        end
        else begin
            zf = 0;
        end
    end
endmodule
