// vim: set ft=systemverilog:

// N bit, 4 input 1 output multiplexer
module mux4 #(
    parameter N = 32
)(
    input [N-1:0] v, // input 1
    input [N-1:0] w, // input 2
    input [N-1:0] x, // input 3
    input [N-1:0] y, // input 4
    input [1:0] sel, // select input
    output reg [N-1:0] z // output
);
    always @(v or w or x or y or sel) begin
        case (sel)
            2'b00: z = v;
            2'b01: z = w;
            2'b10: z = x;
            2'b11: z = y;
        endcase
    end
endmodule
