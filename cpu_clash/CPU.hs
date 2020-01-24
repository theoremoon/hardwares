module CPU where

import Clash.Sized.Unsigned (Unsigned)
import Clash.Sized.Vector (Vec((:>), Nil),  (!!), replace, repeat, (++))
import Clash.Class.Resize (zeroExtend, resize)
import Clash.Sized.BitVector (BitVector, (++#), Bit)
import Clash.Class.BitPack (pack, unpack)
import Clash.Promoted.Nat.Literals as Nat
import Clash.Prelude (slice,System)
import Clash.Signal (Signal,register,sample)
import Prelude (($),(+),(-), error, compare, Ordering(..), fmap,Bool(True,False),take)
import Data.Bits ((.|.), (.&.), xor, shift)

{-- there are four general registers and one flag register --}
data Register
    = R1
    | R2
    | R3
    | R4
    | Flags

{-- this cpu has 9 bit pointer type --}
newtype Ptr = Ptr {dereference :: (Unsigned 9)}


{-- this cpu has 16 instructions
   all instruction has 80 bits --}
data Instruction
    = Add Register Register
    | Sub Register Register
    | And Register Register
    | Or Register Register
    | Xor Register Register
    | Addi Register (Unsigned 64)
    | Subi Register (Unsigned 64)
    | Cmp Register Register
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

{-- General Registers, Flag register, and Instruction Register --}
data Registers = Registers
    { r1 :: Unsigned 64
    , r2 :: Unsigned 64
    , r3 :: Unsigned 64
    , r4 :: Unsigned 64
    , eflags :: Unsigned 64
    , pc :: Ptr
    }

{-- CPU Status is determined by its mode and regsiters --}
data CPUState  = CPUState CPUMode Registers
defaultCPUState :: CPUState
defaultCPUState = CPUState Fetch (Registers 0 0 0 0 0 (Ptr 0))

{-- there are 64 words of memory --}
data RAM = RAM (Vec 64 (Unsigned 64))

{-- utilities --}
zeroFlag = 1 :: Unsigned 64
signFlag = 2 :: Unsigned 64

readZF :: Registers -> Bit
readZF regs =
   case (eflags regs) .&. 1 of
     0 -> 0 :: Bit
     otherwise -> 1 :: Bit

readSF :: Registers -> Bit
readSF regs =
   case (eflags regs) .&. 2 `shift` (-1) of
     0 -> 0 :: Bit
     otherwise -> 1 :: Bit

readRegister :: Registers -> Register -> Unsigned 64
readRegister (Registers r1 r2 r3 r4 _ _) r =
    case r of
      R1 -> r1
      R2 -> r2
      R3 -> r3
      R4 -> r4
      _ -> error "Not a general register"

writeRegister :: Registers -> Register -> Unsigned 64 -> Registers
writeRegister regs r w =
    case r of
      R1 -> regs {r1 = w}
      R2 -> regs {r2 = w}
      R3 -> regs {r3 = w}
      R4 -> regs {r4 = w}
      _ -> error "Not a general register"

readRAM :: RAM -> Ptr -> Unsigned 64
readRAM (RAM ram) (Ptr ptr) = ram !! ptr

writeRAM :: RAM -> Ptr -> Unsigned 64 -> RAM
writeRAM (RAM ram) (Ptr ptr) w = RAM (replace ptr w ram)

nextPC :: Ptr -> Ptr
nextPC (Ptr pc) = Ptr (pc + 1)

{-- Instruction Encoder --}
encode :: Instruction -> Unsigned 64
encode ir =
   unpack $
   case ir of
    Add dst src -> tag 0 ++#  reg dst ++# reg src ++# 0 {-- 4bit + 4bit + 4bit + padding --}
    Sub dst src -> tag 1 ++#  reg dst ++# reg src ++# 0
    And dst src -> tag 2 ++#  reg dst ++# reg src ++# 0
    Or  dst src -> tag 3 ++#  reg dst ++# reg src ++# 0
    Xor dst src -> tag 4 ++#  reg dst ++# reg src ++# 0
    Addi dst imm -> tag 5 ++# reg dst ++# pack (resize imm) {-- 4bit + 4bit + 56bit --}
    Subi dst imm -> tag 6 ++# reg dst ++# pack (resize imm)
    Cmp lhs rhs -> tag 7 ++# reg lhs ++# reg rhs ++# 0
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
decode :: Unsigned 64 -> Instruction
decode code =
   case tag of
     0 -> Add dst src
     1 -> Sub dst src
     2 -> And dst src
     3 -> Or  dst src
     4 -> Xor dst src
     5 -> Addi dst imm
     6 -> Subi dst imm
     7 -> Cmp dst src
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
      imm = unpack $ zeroExtend $ slice Nat.d51 Nat.d0 code
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
                  src' = readRegister regs src
                  dst' = readRegister regs dst
                  regs' = writeRegister regs dst (dst' + src')
         Sub dst src ->
            (CPUState Fetch regs', ram)
               where
                  src' = readRegister regs src
                  dst' = readRegister regs dst
                  regs' = writeRegister regs dst (dst' - src')
         And dst src ->
            (CPUState Fetch regs', ram)
              where
                  src' = pack $ readRegister regs src
                  dst' = pack $ readRegister regs dst
                  regs' = writeRegister regs dst (unpack (dst' .&. src'))
         Or  dst src ->
            (CPUState Fetch regs', ram)
              where
                  src' = pack $ readRegister regs src
                  dst' = pack $ readRegister regs dst
                  regs' = writeRegister regs dst (unpack (dst' .|. src'))
         Xor dst src ->
            (CPUState Fetch regs', ram)
              where
                  src' = pack $ readRegister regs src
                  dst' = pack $ readRegister regs dst
                  regs' = writeRegister regs dst (unpack (dst' `xor` src'))
         Addi dst imm ->
            (CPUState Fetch regs', ram)
              where
                  dst' = readRegister regs dst
                  regs' = writeRegister regs dst (dst' + imm)
         Subi dst imm ->
            (CPUState Fetch regs', ram)
              where
                  dst' = readRegister regs dst
                  regs' = writeRegister regs dst (dst' - imm)
         Cmp lhs rhs ->
            (CPUState Fetch regs', ram)
               where
                  lhs' = pack $ readRegister regs lhs
                  rhs' = pack $ readRegister regs rhs
                  flags =
                     case compare lhs' rhs' of
                     EQ -> zeroFlag
                     LT -> signFlag
                     otherwise -> 0
                  regs' = regs { eflags = flags }
         Ld dst src ->
            (CPUState Fetch regs', ram)
              where
                  dst' = pack $ readRegister regs dst
                  addr = Ptr (resize (readRegister regs src))
                  regs' = writeRegister regs dst (readRAM ram addr)
         St dst src ->
            (CPUState Fetch regs, ram')
              where
                  src' = readRegister regs src
                  addr = Ptr (resize (readRegister regs dst))
                  ram' = writeRAM ram addr src'
         Jmp ptr ->
            (CPUState mode regs', ram)
               where
                  ptr' = dereference (pc regs)
                  regs' = regs {pc = Ptr ptr'}
         Jz ptr ->
            (CPUState mode regs', ram)
               where
                  ptr' = dereference (pc regs)
                  regs' =
                     case readZF regs of
                     1 -> regs {pc = Ptr ptr'}
                     otherwise -> regs
         Jg ptr ->
            (CPUState mode regs', ram)
               where
                  ptr' = dereference (pc regs)
                  regs' =
                     case (readZF regs, readSF regs) of
                     (0, 0) -> regs {pc = Ptr ptr'}
                     otherwise -> regs
         Halt ->
            (CPUState Stopped regs, ram)
    Stopped -> (CPUState mode regs, ram)


program
   {-- Initialize --}
   = Xor R1 R1
   :> Xor R2 R2
   :> Xor R3 R3
   :> Xor R4 R4
   :> Addi R1 1
   :> Addi R2 1
   :> Addi R3 10 {-- Store 10 at 0 --}
   :> St R4 R3
   :> Xor R3 R3  {-- make R3 to 0 --}
   :> Xor R4 R4  {-- LOOP --}
   :> Addi R4 1  {-- Calculate Fibonacci --}
   :> St R4 R1
   :> Add R1 R2
   :> Ld R2 R4
   :> Addi R3 1  {-- continue / break --}
   :> St R4 R1   {-- save R1 to 1 --}
   :> Xor R4 R4  {-- load loop times to R1 --}
   :> Ld R1 R4
   :> Cmp R1 R3
   :> Ld R1 R4
   :> Jz (Ptr 22)
   :> Jmp (Ptr 9)
   :> Halt
   :> Nil

encodedProgram = fmap encode program ++ repeat 0

isHalted :: CPUState -> Bool
isHalted (CPUState mode _) =
   case mode of
     Stopped -> True
     otherwise -> False

getR1 :: CPUState -> (Unsigned 64)
getR1 (CPUState _ regs) =readRegister regs R1

getOutput :: (CPUState, RAM) -> (Bool, Unsigned 64)
getOutput (state, _) = (isHalted state, getR1 state)

cpuHardware :: CPUState -> RAM -> Signal System (Bool, Unsigned 64)
cpuHardware initialCPUState initialRAM = outputSignal
   where systemState = register (initialCPUState, initialRAM) systemState'
         systemState' = fmap cycle systemState
         outputSignal = fmap getOutput systemState'

cpu = cpuHardware defaultCPUState (RAM encodedProgram)

hardwareTranslate :: (Bool, Unsigned 64) -> (Bit, BitVector 64)
hardwareTranslate (halted, output) = (haltedBit, outputValue)
   where
      haltedBit = if halted then 1 else 0
      outputValue = pack output

topEntity :: Signal System (Bit, BitVector 64)
topEntity = fmap hardwareTranslate cpu
