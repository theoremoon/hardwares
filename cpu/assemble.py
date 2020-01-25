import sys
import re

if len(sys.argv) == 1:
    print("Usage: {} <asm>".format(sys.argv[0]))
    exit(1)

instructions = {
    "Xor": "100110",
    "Addi": "001000",
    "Halt": "111111",
}
registers = {
    "R0": "00000",
    "R1": "00001",
    "R2": "00010",
    "R3": "00011",
}

def chunks(xs, n):
    for i in range(0, len(xs), n):
        yield xs[i:i+n]


with open(sys.argv[1], "r") as f:
    codes = ["ff ff ff ff"] * 1024
    for i, line in enumerate(f):
        print(repr(line))
        l = line.strip().split()
        code = ""
        code += instructions[l[0]] # opcode

        for op in l[1:]:
            if re.match("R[0-3]", op):
                code += registers[op]
            elif re.match("0[xX][0-9A-Fa-f]{1,4}", op):
                code += "{:016b}".format(int(op[2:], 16))
            else:
                print("[!] invalid operand: {}".format(op))
                exit(1)
        codes[i] = "{:08x}".format(int(code.ljust(32, "0"), 2))
        codes[i] = " ".join(chunks(codes[i], 2)) + "  // " + line.strip()

with open(sys.argv[1].rsplit(".", 1)[0] + ".hex", "w") as f:
    f.write("\n".join(codes))




