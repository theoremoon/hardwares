module CPU where

import Clash.Sized.Unsigned (Unsigned)
import Clash.Sized.Vector (Vec((:>), Nil),  (!!), replace, repeat, (++))
import Clash.Class.Resize (zeroExtend, resize)
import Clash.Sized.BitVector (BitVector, (++#), Bit)
import Clash.Class.BitPack (pack, unpack)
import Clash.Promoted.Nat.Literals as Nat
import Clash.Prelude (slice)
import Prelude (($),(+),(-), error)
import Data.Bits ((.|.), (.&.), xor)

{-- there are four registers --}
data Register
    = R1
    | R2
    | R3
    | R4

{-- this cpu has 9 bit pointer type --}
newtype Ptr = Ptr (Unsigned 9)

{-- this cpu has 64 bit size as a word --}
newtype Word = Word {value :: (Unsigned 64)}


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
    | Ld Register Register
    | St Register Register
    | Jmp Ptr
    | Jz Ptr
    | Jg Ptr
    | Halt

{-- CPU Modes --}
data CPUMode
    = Fetch
    | Exec Instruction
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
data CPUState  = CPUState CPUMode Registers


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

nextPC :: Ptr -> Ptr
nextPC (Ptr pc) = Ptr (pc + 1)

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
     5 -> Addi dst imm
     6 -> Subi dst imm
     10 -> Ld dst src
     11 -> St dst src
     12 -> Jmp ptr
     13 -> Jz ptr
     14 -> Jg ptr
     15 -> Halt
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

{-- do CPU Logic --}
cycle :: (CPUState, RAM) -> (CPUState, RAM)
cycle (CPUState mode regs, ram) =
   case mode of
    Fetch ->
       (CPUState mode' regs', ram)
          where
             ir = readRAM ram (pc regs)
             mode' = Exec (decode ir)
             regs' = regs { pc = nextPC (pc regs)}
    Exec ir ->
       case ir of
         Add dst src ->
            (CPUState Fetch regs', ram)
               where
                  src' = value (readRegister regs src)
                  dst' = value (readRegister regs dst)
                  regs' = writeRegister regs dst (Word (dst' + src'))
         Sub dst src ->
            (CPUState Fetch regs', ram)
               where
                  src' = value (readRegister regs src)
                  dst' = value (readRegister regs dst)
                  regs' = writeRegister regs dst (Word (dst' - src'))
         And dst src ->
            (CPUState Fetch regs', ram)
              where
                  src' = pack $ value (readRegister regs src)
                  dst' = pack $ value (readRegister regs dst)
                  regs' = writeRegister regs dst (Word (unpack (dst' .&. src')))
         Or  dst src ->
            (CPUState Fetch regs', ram)
              where
                  src' = pack $ value (readRegister regs src)
                  dst' = pack $ value (readRegister regs dst)
                  regs' = writeRegister regs dst (Word (unpack (dst' .|. src')))
         Xor dst src ->
            (CPUState Fetch regs', ram)
              where
                  src' = pack $ value (readRegister regs src)
                  dst' = pack $ value (readRegister regs dst)
                  regs' = writeRegister regs dst (Word (unpack (dst' `xor` src')))
         Addi dst imm ->
            (CPUState Fetch regs', ram)
              where
                  dst' = value (readRegister regs dst)
                  imm' = value imm
                  regs' = writeRegister regs dst (Word (dst' + imm'))
         Subi dst imm ->
            (CPUState Fetch regs', ram)
              where
                  dst' = value (readRegister regs dst)
                  imm' = value imm
                  regs' = writeRegister regs dst (Word (dst' - imm'))
         Ld dst src ->
            (CPUState Fetch regs', ram)
              where
                  dst' = pack $ value (readRegister regs dst)
                  addr = Ptr (resize (value (readRegister regs src)))
                  regs' = writeRegister regs dst (readRAM ram addr)
         St dst src ->
            (CPUState Fetch regs, ram')
              where
                  src' = readRegister regs src
                  addr = Ptr (resize (value (readRegister regs dst)))
                  ram' = writeRAM ram addr src'
         Jmp ptr ->(CPUState mode regs, ram) {-- TO DO NEXT IS IMPLEMENT CMP INSTRUCTION AND JUMPS --}
         Jz ptr ->(CPUState mode regs, ram)
         Jg ptr ->(CPUState mode regs, ram)
         _ -> (CPUState mode regs, ram)
    Stopped -> (CPUState mode regs, ram)



