import sys
import re

if len(sys.argv) == 1:
    print("Usage: {} <asm>".format(sys.argv[0]))
    exit(1)

def chunks(xs, n):
    for i in range(0, len(xs), n):
        yield xs[i:i+n]

registers = {
    "$at": 1,
    "$sp": 13,
    "$fp": 14,
    "$ra": 15,
}

instructions = {
    "ADD":  "000010",
    "ADDi": "000011",
    "SUB":  "000100",
    "SUBi": "000101",
    "MUL":  "000110",
    "MULi": "000111",
    "DIV":  "001000",
    "DIVi": "001001",
    "AND":  "001010",
    "ANDi": "001011",
    "OR":   "001100",
    "ORi":  "001101",
    "XOR":  "001110",
    "XORi": "001111",
    "NOR":  "010000",
    "NORi": "010001",
    "SLL":  "010010",
    "SLLi": "010011",
    "SLR":  "010100",
    "SLRi": "010101",
    "SLT":  "010110",
    "SLTi": "010111",
    "LB":   "011010",
    "SB":   "011011",
    "LH":   "011100",
    "SH":   "011101",
    "LW":   "011110",
    "SW":   "011111",
    "BEQ":  "100000",
    "BNE":  "100001",
    "J":    "100010",
    "JR":   "100011",
    "JAL":  "100100",
    "MFHI": "100101",
    "HALT": "111111",
}

def enter(asm, opcode, operands, comment):
    asm.addInst("SW", ["$ra", "$sp", hex(0)], comment)
    asm.addInst("SW", ["$fp", "$sp", hex(4)])
    asm.addInst("ADDi", ["$fp", "$sp", hex(8)])

def ret(asm, opcode, operands, comment):
    asm.addInst("ADDi", ["$sp", "$0", "$fp"], comment)
    asm.addInst("LW", ["$fp", "$sp", hex(4)])
    asm.addInst("LW", ["$ra", "$sp", hex(0)])
    asm.addInst("JR", ["$ra"])

def bcond(is_gt, is_eq):
    def f(asm, opcode, operands, comment):
        if is_gt:
            asm.addInst("SLT", ["$at"] + operands[:2:-1], comment)
        else:
            asm.addInst("SLT", ["$at"] + operands[:2], comment)
        if is_eq:
            asm.addInst("BEQ", ["$at", "$0", operands[2]])
        else:
            asm.addInst("BNE", ["$at", "$0", operands[2]])
    return f

specials = {
    "ENTER": enter,
    "RET": ret,

    "BGT": bcond(True, False),
    "BLT": bcond(False, False),
    "BGE": bcond(True, True),
    "BLE": bcond(False, True),
}

class Assemble():
    def __init__(self):
        self.i = 0 # instruction number
        self.labels = {}
        self.inst = []

    def addLabel(self, name):
        self.labels[name] = self.i * 4

    def genCode(self):
        codes = ["ff ff ff ff"] * 1024

        for i in range(len(self.inst)):
            code, label, comment = self.inst[i]
            if label:
                code = code.format(self.labels[label])

            print(code.ljust(32, "0"))
            code = "{:08x}".format(int(code.ljust(32, "0"), 2))
            codes[i] = " ".join(chunks(code, 2))
            if comment:
                codes[i] += " //" + comment
        return codes

    def addInst(self, opcode, operands, comment = ""):
        print(opcode, operands)
        code = instructions[opcode]
        label = None
        for op in operands:
            if re.match("\\$[0-9]{1,2}", op):
                # REGISTER
                code += "{:04b}".format(int(op[1:]))
            elif op in registers:
                # $fp, $sp
                code += "{:04b}".format(registers[op])
            elif re.match("0[xX][0-9A-Fa-f]{1,4}", op):
                # immediate
                code += "{:018b}".format(int(op[2:], 16))
            elif re.match("[0-9]{1,5}", op):
                # immediate
                code += "{:018b}".format(int(op, 10))
            elif re.match("[A-Za-z0-9_]+", op):
                # label
                label = op
                code += "{:012b}"
            else:
                raise Exception("[!] invalid operand: {}".format(op))
        self.inst.append([code, label, comment])
        self.i += 1

asm = Assemble()
with open(sys.argv[1], "r") as f:
    for line in f:
        l = line.strip().split('#')[0].split()
        if not l:
            continue

        if re.match("[A-Za-z0-9_]+:", l[0]):
            # set label
            asm.addLabel(l[0][:-1])
            continue

        opcode, operands = l[0], l[1:]
        if opcode in specials:
            specials[opcode](asm, opcode, operands, line.strip())
        else:
            asm.addInst(opcode, operands, line.strip())

codes = asm.genCode()
with open("program.hex", "w") as f:
    f.write("\n".join(codes))


