.macro print_str(%str)
    la a0, %str
    li a7, 4
    ecall
.end_macro

.macro read_str(%buffer, %length)
    la a0, %buffer
    li a1, %length
    li a7, 8
    ecall
.end_macro

.macro open_file(%filename, %mode)
    la a0, %filename
    li a1, %mode
    li a7, 1024
    ecall
.end_macro

.macro close_file(%descriptor)
    mv a0, %descriptor
    li a7, 57
    ecall
.end_macro

.macro seek_file(%descriptor, %position, %whence)
    mv a0, %descriptor
    mv a1, %position
    li a2, %whence
    li a7, 62
    ecall
.end_macro

.macro read_file(%descriptor, %buffer, %count)
    mv a0, %descriptor
    mv a1, %buffer
    li a2, %count
    li a7, 63
    ecall
.end_macro

.macro write_file(%descriptor, %buffer, %count)
    mv a0, %descriptor
    mv a1, %buffer
    li a2, %count
    li a7, 64
    ecall
.end_macro