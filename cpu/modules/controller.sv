// vim: set ft=systemverilog:


// 32 bit cpu controller
module controller (
    input [N-1:0] instr,
    output reg [1:0] r1, // register id to load
    output reg [1:0] r2,
    output reg [1:0] w1, // register id to write
    output reg [N-1:0] imm,
    output reg imm_flag,  // when true, use imm instead of r2
    output reg [N-1:0] mask, // register/memory write mask
    output reg mem_read, // when true, use memory value
    output reg pc_read, // when true, store pc value to register
    output reg is_jz, // when true, next instruction is detemined by jz
    output reg is_jg, // when true, next instruction is detemined by jg
    output reg is_halted // when true, the cpu is halted
);
    localparam N = 32; // N is bit width of the instruction
    localparam M = 16; // M is bit width of the address space

    reg halted_flag;

    initial begin
        halted_flag = 0;
    end

    always @(instr) begin
        if (halted_flag == 0) begin
            case (instr)
                default: begin
                    // unknown instruction
                    halted_flag = 1;
                end
            endcase
        end

        if (halted_flag) begin
            r1 = 0;
            r2 = 0;
            w1 = 3'b000;
            imm = 0;
            imm_flag = 0;
            mask = 0;
            mem_read = 0;
            pc_read = 0;
            is_jz = 0;
            is_jg = 0;
            is_halted = 1;
        end
    end
endmodule
