// vim: set ft=systemverilog:

// N bit 2 input 1 output multiplexer
module mux2 #(
    parameter N = 32
)(
    input [N-1:0] x, // input 1
    input [N-1:0] y, // input 2
    input sel, // select input
    output [N-1:0] z // output
);
    assign z = (sel == 0) ? x : y;
endmodule
