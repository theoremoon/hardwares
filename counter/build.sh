#!/bin/sh
module="Counter"
clash *hs --vhdl
cd vhdl/$module/; ghdl -a *.vhdl
cd testbench; ghdl -a *.vhdl; ghdl -e testbench; ghdl -r testbench --vcd=test.vcd

