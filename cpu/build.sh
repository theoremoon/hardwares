test() {
    iverilog "modules/$1.sv" "testbenches/$1_test.sv" -o "$1_test"
    vvp "$1_test"
}
view() {
    test "$1"
    gtkwave "$1_test.vcd"
}
cpu() {
    iverilog modules/*.sv -o cpu
    vvp "cpu"
}
