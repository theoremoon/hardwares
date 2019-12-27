module CPU where

import Clash.Sized.Unsigned (Unsigned)
import Clash.Sized.Vector (Vec((:>), Nil),  (!!), replace, repeat, (++))
import Clash.Class.Resize (zeroExtend, resize)
import Clash.Sized.BitVector (BitVector, (++#), Bit)
import Clash.Class.BitPack (pack, unpack)
import Clash.Promoted.Nat.Literals as Nat
import Clash.Prelude (slice)
import Prelude (($), error)

{-- there are four registers --}
data Register
    = R1
    | R2
    | R3
    | R4

{-- this cpu has 9 bit pointer type --}
newtype Ptr = Ptr (Unsigned 9)

{-- this cpu has 64 bit size as a word --}
newtype Word = Word (Unsigned 64)


{-- this cpu has 16 instructions
   all instruction has 80 bits --}
data Instruction
    = Add Register Register
    | Sub Register Register
    | And Register Register
    | Or Register Register
    | Xor Register Register
    | Addi Register Word
    | Subi Register Word
    | Inc Register
    | Dec Register
    | Ld Register Register
    | St Register Register
    | Jmp Ptr
    | Jz Ptr
    | Jg Ptr
    | Halt

{-- CPU Modes --}
data CPUActivity
    = Fetch
    | Exec
    | Stopped

{-- General Registers and Instruction Register --}
data Registers = Registers
    { r1 :: Word
    , r2 :: Word
    , r3 :: Word
    , r4 :: Word
    , pc :: Ptr
    }

{-- CPU Status is determined by its mode and regsiters --}
data CPUState  = CPUState CPUActivity Registers


{-- there are 64 words of memory --}
data RAM = RAM (Vec 64 Word)

{-- utilities --}
readRegister :: Registers -> Register -> Word
readRegister (Registers r1 r2 r3 r4 _) r =
    case r of
      R1 -> r1
      R2 -> r2
      R3 -> r3
      R4 -> r4

writeRegister :: Registers -> Register -> Word -> Registers
writeRegister regs r w =
    case r of
      R1 -> regs {r1 = w}
      R2 -> regs {r2 = w}
      R3 -> regs {r3 = w}
      R4 -> regs {r4 = w}

readRAM :: RAM -> Ptr -> Word
readRAM (RAM ram) (Ptr ptr) = ram !! ptr

writeRAM :: RAM -> Ptr -> Word -> RAM
writeRAM (RAM ram) (Ptr ptr) w = RAM (replace ptr w ram)

{-- Instruction Encoder --}
encode :: Instruction -> Word
encode ir =
   Word $ unpack $
   case ir of
    Add dst src -> tag 0 ++#  reg dst ++# reg src ++# 0 {-- 4bit + 4bit + 4bit + padding --}
    Sub dst src -> tag 1 ++#  reg dst ++# reg src ++# 0
    And dst src -> tag 2 ++#  reg dst ++# reg src ++# 0
    Or  dst src -> tag 3 ++#  reg dst ++# reg src ++# 0
    Xor dst src -> tag 4 ++#  reg dst ++# reg src ++# 0
    Addi dst (Word imm) -> tag 5 ++# reg dst ++# pack (resize imm) {-- 4bit + 4bit + 56bit --}
    Subi dst (Word imm) -> tag 6 ++# reg dst ++# pack (resize imm)
    Inc dst -> tag 7 ++# 0
    Dec dst -> tag 8 ++# 0
    Ld dst src -> tag 10 ++# reg dst ++# reg src ++# 0
    St dst src -> tag 11 ++# reg dst ++# reg src ++# 0
    Jmp (Ptr ptr) -> tag 12 ++# pack ptr ++# 0
    Jz (Ptr ptr) -> tag 13 ++# pack ptr ++# 0
    Jg (Ptr ptr) -> tag 14 ++# pack ptr ++# 0
    Halt -> tag 15 ++# 0
    where
       tag :: BitVector 4 -> BitVector 4
       tag x = x
       reg :: Register -> BitVector 4
       reg R1 = 0
       reg R2 = 1
       reg R3 = 2
       reg R4 = 3

{-- Instruction Decoder --}
decode :: Word -> Instruction
decode (Word code) =
   case tag of
     0 -> Add dst src
     1 -> Sub dst src
     2 -> And dst src
     3 -> Or  dst src
     4 -> Xor dst src
     5 -> Add dst src
     6 -> Addi dst imm
     7 -> Subi dst imm
     8 -> Inc dst
     9 -> Dec dst
     11 -> Ld dst src
     12 -> St dst src
     13 -> Jmp ptr
     14 -> Jz ptr
     15 -> Jg ptr
     16 -> Halt
     _ -> error "Unknown Instruction"
   where
      tag = unpack (slice Nat.d63 Nat.d60 code) :: Unsigned 4
      dst = reg $ slice Nat.d59 Nat.d56 code
      src = reg $ slice Nat.d55 Nat.d52 code
      imm = Word $ unpack $ zeroExtend $ slice Nat.d51 Nat.d0 code
      ptr = Ptr $ unpack $ slice Nat.d63 Nat.d55 code
      reg :: BitVector 4 -> Register
      reg 0 = R1
      reg 1 = R2
      reg 2 = R3
      reg 3 = R4
      reg _ = error "Invalid Register"

