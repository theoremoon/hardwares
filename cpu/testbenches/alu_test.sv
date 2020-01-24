// vim: set ft=systemverilog:

`timescale 1ns/100ps
module test_alu();
    parameter N=32;

    reg [N-1:0]x;
    reg [N-1:0]y;
    wire [N-1:0] z;
    wire zf;
    wire sf;

    alu alu(
        .x(x),
        .y(y),
        .z(z),
        .zf(zf),
        .sf(sf));


    initial begin
        $dumpfile("alu_test.vcd");
        $dumpvars(0, test_alu);

        #10 x = 32'h0; y = 32'h0;
        #10 x = 32'h112233ff; y = 32'h1;
        #10 x = 32'hffffffff; y = 32'h1;
        #10 x = 32'hffffffff; y = 32'hffffffff;
        #10 $finish;
    end
endmodule
