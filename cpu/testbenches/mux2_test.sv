// vim: set ft=systemverilog:

`timescale 1ns/100ps
module test_mux2();
    parameter N=32;

    reg [N-1:0]x;
    reg [N-1:0]y;
    reg sel;
    wire [N-1:0] z;

    mux2 mux2(
        .x(x),
        .y(y),
        .sel(sel),
        .z(z));

    initial begin
        $dumpfile("mux2_test.vcd");
        $dumpvars(0, test_mux2);

        x = 0; y = 0; sel = 0;
        #10 x = 0; y = 0; sel = 1;
        #10 x = 32'hcafebabe; y = 0; sel = 1;
        #10 x = 32'hcafebabe; y = 32'hdeadbeef; sel = 1;
        #10 x = 32'hcafebabe; y = 32'hdeadbeef; sel = 0;
        #10 $finish;
    end
endmodule
