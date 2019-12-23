module Counter where
import Clash.Prelude
import Clash.Explicit.Testbench

counterT state flg =
    if flg == high then
        (state + 1, state + 1)  -- (new state, output)
    else
        (state, state)

counter = mealy counterT 0  -- initial state is 0

topEntity
    :: Clock System  -- use system clock, reset, enable
    -> Reset System
    -> Enable System
    -> Signal System Bit        -- input
    -> Signal System (Signed 8) -- output
topEntity = exposeClockResetEnable counter

testBench :: Signal System Bool
testBench = done
    where
        testInput = stimuliGenerator clk rst $(listToVecTH [low, high, low, low, high, high, high, low])
        expectOutput = outputVerifier' clk rst $(listToVecTH [0 :: (Signed 8), 1, 1, 1, 2, 3, 4, 4])
        done = expectOutput (topEntity clk rst en testInput)
        en = enableGen
        clk = tbSystemClockGen (not <$> done)
        rst = systemResetGen

