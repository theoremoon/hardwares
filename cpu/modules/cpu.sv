// vim: set ft=systemverilog:

// 32 bit cpu
module cpu(
    input clk,
    input rst,
    input [7:0] instructions [4*(2**M)-1:0], // instruction memory
    output reg is_halted
);
    localparam N = 32;
    localparam M = 10;

    reg [M-1:0] pc; // program counter
    reg [N-1:0] instr;

    wire [1:0] r1;
    wire [1:0] r2;
    wire [1:0] w1;
    wire [N-1:0] imm;
    wire imm_flag;
    wire [N-1:0] mask;
    wire halted_flag;
    wire mem_read;
    wire alu_mode;
    wire pc_read;
    wire is_jz;
    wire is_jg;

    wire [N-1:0] v1;
    wire [N-1:0] v2;
    wire [N-1:0] m1;  // imm or v2
    wire [N-1:0] memv;  // value readed from memory

    wire [N-1:0] z;
    wire zf;
    wire sf;
    wire [N-1:0] w;

    controller controller(
        .instr(instr),
        .r1(r1),
        .r2(r2),
        .w1(w1),
        .imm(imm),
        .imm_flag(imm_flag),
        .mask(mask),
        .alu_mode(alu_mode),
        .mem_read(mem_read),
        .pc_read(pc_read),
        .is_jz(is_jz),
        .is_jg(is_jg),
        .is_halted(halted_flag));
    registers registers(
        .clk(clk),
        .r1(r1),
        .r2(r2),
        .w1(w1),
        .mask(mask),
        .w(w),
        .v1(v1),
        .v2(v2));
    mux2 aluinputmux(
        .x(v2),
        .y(imm),
        .sel(imm_flag),
        .z(m1));
    alu alu(
        .x(v1),
        .y(m1),
        .mode(alu_mode),
        .z(z),
        .zf(zf),
        .sf(sf));
    memory memory(
        .clk(clk),
        .address(z[M+2-1:0]),
        .mask(mask),
        .w(v2),
        .v(memv));
    mux4 regwritemux(
        .v(z),
        .w({22'b0, pc}),
        .x(memv),
        .y(32'hx),
        .sel({mem_read, pc_read}),
        .z(w));

    initial begin
        pc = 0;
        is_halted = 0;
    end

    always @(clk or negedge rst) begin
        if (rst == 0) begin
            pc = 0;
        end
        else if (halted_flag == 0) begin
            if (clk) begin
                // FETCH
                instr = {instructions[pc],instructions[pc+1],instructions[pc+2],instructions[pc+3]};
                // automatically executed
            end
            else begin
                // UPDATE PC
                pc = ((is_jz&zf)|(is_jg&(~sf))) ? z[M-1:0] : pc + 4;
                // pc = pc + 4;
        $display("PC: %d", pc);
        $display("INSTR: %x", instr);
        $display("ALUMODE: %d", alu_mode);
        $display("R1: %x", r1);
        $display("R2: %x", r2);
        $display("V1: %x", v1);
        $display("V2: %x", v2);
        $display("mask: %x", mask);
        $display("Imm: %d", imm);
        $display("ImmFlag: %d", imm_flag);
        $display("Halt: %d", halted_flag);
        $display("is_jz: %d", is_jz);
        $display("is_jg: %d", is_jg);
        $display("Z: %x", z);
        $display("zf: %d", zf);
        $display("sf: %d", sf);
        $display("");
            end
        end
        else begin
            is_halted = 1;
        end
    end


endmodule
