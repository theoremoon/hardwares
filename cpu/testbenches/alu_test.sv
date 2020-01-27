// vim: set ft=systemverilog:

`timescale 1ns/100ps
module test_alu();
    parameter N=32;

    reg [N-1:0]x;
    reg [N-1:0]y;
    reg [3:0] mode;
    wire [N-1:0] z;

    alu alu(
        .x(x),
        .y(y),
        .mode(mode),
        .z(z));


    initial begin
        $dumpfile("alu_test.vcd");
        $dumpvars(0, test_alu);

        mode = 4'b0000;
        #10  x = 32'h33333333; y = 32'h02222222; mode = 4'b0001; // ADD
        #10  x = 32'h33333333; y = 32'h02222222; mode = 4'b0010; // SUB
        #10  x = 32'h33333333; y = 32'h02222222; mode = 4'b0011; // MUL
        #10  mode = 4'b1101; // MFHI
        #10  x = 32'h33333333; y = 32'h02222222; mode = 4'b0100; // DIV
        #10  mode = 4'b1101; // MFHI
        #10  x = 32'h33333333; y = 32'h02222222; mode = 4'b0101; // AND
        #10  x = 32'h33333333; y = 32'h02222222; mode = 4'b0110; // OR
        #10  x = 32'h33333333; y = 32'h02222222; mode = 4'b0111; // XOR
        #10  x = 32'h33333333; y = 32'h02222222; mode = 4'b1000; // NOR
        #10  x = 32'h33333333; y = 32'h02222222; mode = 4'b1001; // SLL
        #10  x = 32'h33333333; y = 32'h02222222; mode = 4'b1010; // SLR
        #10  x = 32'h33333333; y = 32'h02222222; mode = 4'b1011; // SLT
        #10  x = 32'h33333333; y = 32'hffffffff; mode = 4'b1011; // SLT
        #10  x = 32'h33333333; y = 32'h02222222; mode = 4'b1110; // EQ
        #10  x = 32'h33333333; y = 32'h11111111; mode = 4'b1110; // EQ
        #10  x = 32'h33333333; y = 32'h02222222; mode = 4'b1111; // NEQ
        #10  x = 32'h33333333; y = 32'h11111111; mode = 4'b1111; // NEQ
        #10 $finish;
    end
endmodule

