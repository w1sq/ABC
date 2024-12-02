.include "macros.asm"
.include "utils.asm"

.data
    test_files:    .string "tests/test1.txt\0tests/test2.txt\0tests/test3.txt\0"
    test_count:    .word 3
    test_out_suffix: .string "_out.txt\0"
    test_msg:      .string "Тестирование файла: "
    tests_dir:     .string "tests/"
    debug_msg1:    .string "Входной файл: "
    debug_msg2:    .string "Выходной файл: "

.text
.globl main
main:
    # Вызываем тестовую программу
    jal test_program
    
    # Завершаем программу
    li a7, 10
    ecall

.globl test_program
test_program:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    lw t0, test_count
    la t1, test_files
    
test_loop:
    beqz t0, test_done
    
    # Выводим имя тестируемого файла
    print_str(test_msg)
    mv a0, t1
    li a7, 4
    ecall
    print_str(newline)
    
    # Копируем имя входного файла
    la a0, filename_in
    mv a1, t1
    jal copy_string
    
    # Отладочный вывод входного файла
    print_str(debug_msg1)
    print_str(filename_in)
    print_str(newline)
    
    # Создаем имя выходного файла
    la a0, filename_out
    mv a1, t1
    jal create_output_name
    
    # Отладочный вывод выходного файла
    print_str(debug_msg2)
    print_str(filename_out)
    print_str(newline)
    
    # Обрабатываем файлы
    jal process_files
    
    # Следующий тест
    addi t0, t0, -1
    find_next:
        lb t2, (t1)
        addi t1, t1, 1
        bnez t2, find_next
    
    j test_loop

test_done:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# Копирование строки
copy_string:
    addi sp, sp, -8
    sw t0, 4(sp)
    sw t1, 0(sp)
copy_loop:
    lb t0, (a1)
    sb t0, (a0)
    beqz t0, copy_done
    addi a0, a0, 1
    addi a1, a1, 1
    j copy_loop
copy_done:
    lw t0, 4(sp)
    lw t1, 0(sp)
    addi sp, sp, 8
    ret

# Создание имени выходного файла (добавляем _out.txt)
create_output_name:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw t0, 8(sp)
    sw t1, 4(sp)
    sw t2, 0(sp)
    
    # Копируем входной путь полностью
    mv t0, a0        # destination
    mv t1, a1        # source
    
base_name_loop:
    lb t2, (t1)
    beqz t2, add_suffix   # если конец строки
    li t3, '.'
    beq t2, t3, add_suffix   # если нашли точку
    sb t2, (t0)
    addi t0, t0, 1
    addi t1, t1, 1
    j base_name_loop
    
add_suffix:
    # Добавляем _out.txt
    la t1, test_out_suffix
suffix_loop:
    lb t2, (t1)
    sb t2, (t0)
    beqz t2, create_name_done
    addi t0, t0, 1
    addi t1, t1, 1
    j suffix_loop
    
create_name_done:
    lw ra, 12(sp)
    lw t0, 8(sp)
    lw t1, 4(sp)
    lw t2, 0(sp)
    addi sp, sp, 16
    ret
