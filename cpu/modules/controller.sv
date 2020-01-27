// vim: set ft=systemverilog:

/*
*
*      immediate flag (if arithmetic/logic instruction)
*      |
* instruction type code
* |||  |
* xxxxxx
*  ||||
*  L---alu opcode
*
* R format: IIIIII|dddd|ssss|tttt
* $d <- $s op $t
*
* I format: IIIIII|dddd|ssss|vvvvvvvvvvvvvvvvvvv
* $d <- $s op v
*
* J format: IIIIII|aaaaaaaaaaaa
* jump to a
*/

/*
*
* 000000
* 000001
* 000010 ADD
* 000011 ADDi
* 000100 SUB
* 000101 SUBi
* 000110 MUL
* 000111 MULi
* 001000 DIV
* 001001 DIVi
* 001010 AND
* 001011 ANDi
* 001100 OR
* 001101 ORi
* 001110 XOR
* 001111 XORi
* 010000 NOR
* 010001 NORi
* 010010 SLL
* 010011 SLLi
* 010100 SLR
* 010101 SLRi
* 010110 SLT
* 010111 SLTi

* 011000
* 011001
* 011010 LB
* 011011 SB
* 011100 LH
* 011101 SH
* 011110 LW
* 011111 SW

* 100000 BEQ
* 100001 BNE
* 100010 J
* 100011 JR
* 100100 JAL
* 100101 MFHI
*/


// 32 bit cpu controller
module controller (
    input clk,
    input [N-1:0] instr,
    output reg [3:0] r1, // register id to load
    output reg [3:0] r2,
    output reg [3:0] w1, // register id to write
    output reg [N-1:0] imm,
    output reg [3:0] alu_mode,
    output reg imm_flag,  // when true, use imm instead of r2
    output reg [N-1:0] mask, // memory/register read/write mask
    output reg reg_write, // register write bit
    output reg mem_write, // memory write bit
    output reg mem_read, // when true, use memory value
    output reg pc_read, // when true, store pc value to register
    output reg is_jump, // when true then jump is taken
    output reg is_branch, // when true and if alu output is 1, then jump is taken
    output reg is_halted // when true, the cpu is halted
);
    localparam N = 32; // N is bit width of the instruction
    localparam M = 16; // M is bit width of the address space

    reg halted_flag;

    initial begin
        is_halted = 0;
        halted_flag = 0;
    end

    always @(posedge clk) begin
        if (halted_flag == 0) begin
            casex (instr[31:29])
                3'b010, 3'b00x: begin
                    // arithmetic/logic operation
                    alu_mode = instr[30:27];
                    if (instr[26] == 0) begin
                        // R format: IIIIII|dddd|ssss|tttt
                        //            ^^^^ ALU opcode
                        w1 = instr[25:22];  // d
                        r1 = instr[21:18];  // s
                        r2 = instr[17:14];  // t
                        imm = 0;
                        imm_flag = 0;
                    end
                    else begin
                        // I format: IIIIII|dddd|ssss|vvvvvvvvvvvvvvvvvvv
                        w1 = instr[25:22];  // d
                        r1 = instr[21:18];  // s
                        r2 = 4'b0;
                        imm = instr[17:0];  // t
                        imm_flag = 1;
                    end
                    mask = 32'hffffffff;
                    reg_write = 1;
                    mem_write = 0;
                    mem_read = 0;
                    pc_read = 0;
                    is_jump = 0;
                    is_branch = 0;
                    halted_flag = 0;
                end
                3'b011: begin
                    // memory operation
                    // I format: IIIIII|dddd|ssss|vvvvvvvvvvvvvvvvvvv
                    alu_mode = 4'b0001; // ADD
                    w1 = instr[25:22];  // d (load)
                    r1 = instr[21:18];  // s
                    r2 = instr[25:22];  // d (store)
                    imm = instr[17:0];  // t
                    imm_flag = 1;
                    mask = {{16{instr[28]&instr[27]}}, {8{instr[28]}}, 8'b11111111};
                    pc_read = 0;
                    is_jump = 0;
                    is_branch = 0;
                    halted_flag = 0;
                    if (instr[26] == 0) begin
                        // Load from memory
                        reg_write = 1;
                        mem_write = 0;
                        mem_read = 1;
                    end
                    else begin
                        // Store to memory
                        reg_write = 0;
                        mem_write = 1;
                        mem_read = 0;
                    end
                end
                3'b100: begin
                    // jump / branch operation
                    case (instr[31:26])
                        6'b100000: begin
                            // BEQ
                            // I format: IIIIII|dddd|ssss|vvvvvvvvvvvvvvvvvvv
                            alu_mode = 4'b1110; // EQ  ($d == $t then 1)
                            r1 = instr[25:22]; // d
                            r2 = instr[21:18]; // s
                            w1 = 0;
                            imm = instr[17:0];  // t (offset)
                            imm_flag = 0;
                            mask = 0;
                            reg_write = 0;
                            mem_write = 0;
                            mem_read = 0;
                            pc_read = 0;
                            is_jump = 0;
                            is_branch = 1;
                            end

                        6'b100001: begin
                            // BNE
                            // I format: IIIIII|dddd|ssss|vvvvvvvvvvvvvvvvvvv
                            alu_mode = 4'b1111; // NEQ  ($d != $t then 1)
                            r1 = instr[25:22]; // d
                            r2 = instr[21:18]; // s
                            w1 = 0;
                            imm = instr[17:0];  // t (offset)
                            imm_flag = 0;
                            mask = 0;
                            reg_write = 0;
                            mem_write = 0;
                            mem_read = 0;
                            pc_read = 0;
                            is_jump = 0;
                            is_branch = 1;
                        end
                        6'b100010: begin
                            // J
                            // J format: IIIIII|aaaaaaaaaaaa
                            alu_mode = 4'b0001; // ADD
                            r1 = 0; // $0
                            r2 = 0;
                            w1 = 0;
                            imm = instr[25:14];
                            imm_flag = 1;
                            mask = 0;
                            reg_write = 0;
                            mem_write = 0;
                            mem_read = 0;
                            pc_read = 0;
                            is_jump = 1;
                            is_branch = 0;
                        end
                        6'b100011: begin
                            // JR
                            // I format: IIIIII|dddd|-----------------------
                            alu_mode = 4'b0001; // ADD
                            r1 = 0; // $0
                            r2 = instr[25:22];  // d
                            w1 = 0;
                            imm = instr[25:14];
                            imm_flag = 1;
                            mask = 0;
                            reg_write = 0;
                            mem_write = 0;
                            mem_read = 0;
                            pc_read = 0;
                            is_jump = 1;
                            is_branch = 0;
                        end
                        6'b100100: begin
                            // JAL
                            // J format: IIIIII|aaaaaaaaaaaa
                            alu_mode = 4'b0001; // ADD
                            r1 = 0; // $0
                            r2 = 0;
                            w1 = 4'b1111; // $ra
                            imm = instr[25:14];
                            imm_flag = 1;
                            mask = 32'hffffffff;
                            reg_write = 1;
                            mem_write = 0;
                            mem_read = 0;
                            pc_read = 1;
                            is_jump = 1;
                            is_branch = 0;
                        end
                        6'b100101: begin
                            // MFHI
                            // R format: IIIIII|dddd|----|----
                            alu_mode = 4'b1101; // MFHI
                            w1 = instr[25:22];  // d
                            r1 = 0;
                            r2 = 0;
                            imm = 0;
                            imm_flag = 0;
                            mask = 32'hffffffff;
                            reg_write = 1;
                            mem_write = 0;
                            mem_read = 0;
                            pc_read = 0;
                            is_jump = 0;
                            is_branch = 0;
                        end
                        default: begin
                            // illegal instruction
                            halted_flag = 1;
                        end
                    endcase
                end
                default: begin
                    // illegal instruction
                    halted_flag = 1;
                end
            endcase
        end

        if (halted_flag) begin
            alu_mode = 1'b0;
            r1 = 0;
            r2 = 0;
            w1 = 2'b00;
            imm = 0;
            imm_flag = 0;
            mask = 0;
            reg_write = 0;
            mem_write = 0;
            mem_read = 0;
            pc_read = 0;
            is_jump = 0;
            is_branch = 0;
            is_halted = 1;
        end
    end
endmodule
