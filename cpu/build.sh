test() {
    iverilog "modules/$1.sv" "testbenches/$1_test.sv" -o "$1_test" -g2005-sv && vvp "$1_test"
}
view() {
    gtkwave "$1_test.vcd"
}
cpu() {
    iverilog modules/*.sv testbenches/cpu_test.sv -o cpu_test -g2005-sv && vvp "cpu_test"
}
