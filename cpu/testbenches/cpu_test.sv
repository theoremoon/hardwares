// vim: set ft=systemverilog:

`timescale 10ns/1ns
module test_cpu();
    parameter N=32;
    localparam M = 10;

    reg clk;
    reg rst;
    reg [7:0] instructions [0:4*(2**M)-1];
    wire is_halted;

    cpu cpu(
        .clk(clk),
        .rst(rst),
        .instructions(instructions),
        .is_halted(is_halted));

    always #100 begin
        clk <= !clk;
        if (is_halted) begin
            $finish;
        end
    end

    initial begin
        $dumpfile("cpu_test.vcd");
        $dumpvars(0, test_cpu);
        $readmemh("program.hex", instructions);

        rst = 0; clk = 1;
        #1000 rst = 1;
    end
   /*

   localparam N = 32;
   localparam M = 10;
   reg clk;
   reg [7:0] instructions [4*(2**M)-1:0];
   reg [M-1:0] pc; // program counter
   reg [N-1:0] instr;
   wire [3:0] r1;
   wire [3:0] r2;
   wire [3:0] w1;
   wire [N-1:0] mask;
   wire reg_write;
   wire [N-1:0] w;
   wire [N-1:0] imm;
   wire imm_flag;
   wire [3:0] mode;
   wire [N-1:0]v1;
   wire [N-1:0]v2;
   wire [N-1:0] z;

    controller controller(
        // input
        .clk(clk),
        .instr(instr),
        // output
        .alu_mode(mode),
        .imm(imm),
        .imm_flag(imm_flag),
        .r1(r1),
        .r2(r2),
        .w1(w1),
        .mask(mask),
        .reg_write(reg_write));

   defparam regs.M = 4;
   registers regs(
       .clk(clk),
       .r1(r1),
       .r2(r2),
       .w1(w1),
       .mask(mask),
       .wf(reg_write),
       .w(z),
       .v1(v1),
       .v2(v2));

   alu alu(
       .clk(clk),
       .x(v1),
       .y(imm_flag ? imm : v2),
       .mode(mode),
       .z(z));


   always #5 begin
       clk <= !clk;
   end

   always @(posedge clk) begin
       pc <= pc + 4;
   end

   assign instr = {instructions[pc],instructions[pc+1],instructions[pc+2],instructions[pc+3]};
   initial begin
        $dumpfile("cpu_test.vcd");
        $dumpvars(0, test_cpu);
        $readmemh("program.hex", instructions);
        clk = 0; pc = 0;

        #100 $finish;
   end
   */


endmodule
