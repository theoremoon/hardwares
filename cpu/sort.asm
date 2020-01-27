MAIN:
    # store variables
    ADDi $2 $0 0 # 0
    ADDi $3 $0 0

    ADDi $4 $0 4
    SB $4 $3 0
    ADDi $3 $3 1

    ADDi $4 $0 10
    SB $4 $3 0
    ADDi $3 $3 1

    ADDi $4 $0 1
    SB $4 $3 0
    ADDi $3 $3 1

    ADDi $4 $0 5
    SB $4 $3 0
    ADDi $3 $3 1

    ADDi $4 $0 100
    SB $4 $3 0
    ADDi $3 $3 1

    ADDi $4 $0 2
    SB $4 $3 0
    ADDi $3 $3 1

    JAL SORT

    # load
    ADDi $2 $0 0
    LB $3 $2 0
    LB $3 $2 1
    LB $3 $2 2
    LB $3 $2 3
    LB $3 $2 4
    LB $3 $2 5
    HALT

SORT:
    # $2 array begin
    # $3 array size
    # $4 loop counter 1
    # $5 loop counter 2
    # $6 buffer
    # $7 buffer
    # $8 memory address
    # $9 tmp
    ADDi $4 $0 0
    SUBi $3 $3 1
LOOP1: # while i < N - 1
    BGE $4 $3 LOOP1_END
    ADDi $5 $0 0
LOOP2: # while j < i
    BGE $5 $4 LOOP2_END

    # arr[j], arr[j+1]
    ADD $8 $2 $5
    LB $6 $8 0
    LB $7 $8 1
    # if (arr[j] > arr[j+1]) then swap
    BLE $6 $7 SKIP
    SB $7 $8 0
    SB $6 $8 1
SKIP:
    ADDi $5 $5 1
    J LOOP2
LOOP2_END:
    ADDi $4 $4 1
LOOP1_END:
    JR $ra
