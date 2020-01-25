// vim: set ft=systemverilog:

module alu #(
    parameter N = 32 // bit width
)(
    input [N-1:0] x,
    input [N-1:0] y,
    input mode,
    output reg [N-1:0] z,
    output reg zf,
    output reg sf
);
    always @(x or y) begin
        case (mode)
            1'b0: z = x + y;
            1'b1: z = x ^ y;
        endcase

        zf = (z == 0);
        sf = (z[N-1] == 1);
    end
endmodule
