test() {
    iverilog modules/*.v testbenches/*.v -o test
    vvp test
}
view() {
    gtkwave register_test.vcd
}
