// vim: set ft=systemverilog:

`timescale 1ns/100ps
module test_mux4();
    parameter N=32;

    reg [N-1:0]v;
    reg [N-1:0]w;
    reg [N-1:0]x;
    reg [N-1:0]y;
    reg [1:0] sel;
    wire [N-1:0] z;

    mux4 mux4(
        .v(v),
        .w(w),
        .x(x),
        .y(y),
        .sel(sel),
        .z(z));

    initial begin
        $dumpfile("mux4_test.vcd");
        $dumpvars(0, test_mux4);

        v = 0; w = 0; x = 0; y = 0; sel = 0;
        #10 v = 32'h89abcdef; w = 32'hc0be5417; x = 32'hcafebabe; y = 32'hdeadbeef; sel = 0;
        #10 sel = 1;
        #10 sel = 2;
        #10 sel = 3;
        #10 y = 32'hffffffff;
        #10 $finish;
    end
endmodule
