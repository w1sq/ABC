.data
    filename_in:  .space 256    # Буфер для имени входного файла
    filename_out: .space 256    # Буфер для имени выходного файла
    prompt_in:   .string "Введите имя входного файла: "
    prompt_out:  .string "Введите имя выходного файла: "
    error_msg:   .string "Ошибка при работе с файлом\n"

.text
.globl main
main:
    # Сохраняем ra
    addi sp, sp, -4
    sw ra, 0(sp)
    
    # Получаем имена файлов
    jal get_filenames
    
    # Открываем файлы и обрабатываем данные
    jal process_files
    
    # Восстанавливаем ra и завершаем программу
    lw ra, 0(sp)
    addi sp, sp, 4
    li a7, 10
    ecall

# Подпрограмма получения имен файлов
get_filenames:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    # Запрос имени входного файла
    la a0, prompt_in
    li a7, 4
    ecall
    
    la a0, filename_in
    li a1, 256
    li a7, 8
    ecall
    
    # Удаление \n из входного имени
    la a0, filename_in
    jal remove_newline
    
    # Запрос имени выходного файла
    la a0, prompt_out
    li a7, 4
    ecall
    
    la a0, filename_out
    li a1, 256
    li a7, 8
    ecall
    
    # Удаление \n из выходного имени
    la a0, filename_out
    jal remove_newline
    
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# Подпрограмма обработки файлов
process_files:
    # Сохраняем используемые регистры
    addi sp, sp, -20
    sw ra, 16(sp)
    sw t3, 12(sp)    # для дескриптора входного файла
    sw t4, 8(sp)     # для размера файла
    sw t5, 4(sp)     # для дескриптора выходного файла
    sw t0, 0(sp)     # для текущей позиции
    
    # Открытие входного файла
    la a0, filename_in
    li a1, 0
    li a7, 1024
    ecall
    bltz a0, file_error
    mv t3, a0
    
    # Получение размера файла
    mv a0, t3
    li a1, 0
    li a2, 2
    li a7, 62
    ecall
    mv t4, a0
    
    # Открытие выходного файла
    la a0, filename_out
    li a1, 1
    li a7, 1024
    ecall
    bltz a0, file_error
    mv t5, a0
    
    # Вызов подпрограммы для реверса файла
    mv a0, t3        # входной дескриптор
    mv a1, t5        # выходной дескриптор
    mv a2, t4        # размер файла
    jal reverse_file
    
    # Закрытие файлов
    mv a0, t3
    li a7, 57
    ecall
    
    mv a0, t5
    li a7, 57
    ecall
    
    # Восстанавливаем регистры
    lw ra, 16(sp)
    lw t3, 12(sp)
    lw t4, 8(sp)
    lw t5, 4(sp)
    lw t0, 0(sp)
    addi sp, sp, 20
    ret

# Подпрограмма реверса файла
reverse_file:
    # a0 - входной дескриптор
    # a1 - выходной дескриптор
    # a2 - размер файла
    
    addi sp, sp, -16
    sw ra, 12(sp)
    sw t0, 8(sp)     # для позиции
    sw t1, 4(sp)     # для входного дескриптора
    sw t2, 0(sp)     # для выходного дескриптора
    
    mv t1, a0        # сохраняем входной дескриптор
    mv t2, a1        # сохраняем выходной дескриптор
    addi t0, a2, -1  # начинаем с последней позиции
    
    # Выделяем место для символа
    addi sp, sp, -1

read_loop:
    bltz t0, reverse_done
    
    # Устанавливаем позицию
    mv a0, t1
    mv a1, t0
    li a2, 0
    li a7, 62
    ecall
    
    # Читаем символ
    mv a0, t1
    mv a1, sp
    li a2, 1
    li a7, 63
    ecall
    
    # Записываем символ
    mv a0, t2
    mv a1, sp
    li a2, 1
    li a7, 64
    ecall
    
    addi t0, t0, -1
    j read_loop

reverse_done:
    # Освобождаем место символа
    addi sp, sp, 1
    
    # Восстанавливаем регистры
    lw ra, 12(sp)
    lw t0, 8(sp)
    lw t1, 4(sp)
    lw t2, 0(sp)
    addi sp, sp, 16
    ret

# Функция для удаления символа новой строки из строки
remove_newline:
    # Сохраняем используемые регистры на стеке
    addi sp, sp, -16
    sw ra, 12(sp)
    sw t0, 8(sp)
    sw t1, 4(sp)
    sw t2, 0(sp)
    
    mv t0, a0           # Получаем адрес строки из a0
remove_loop:
    lb t1, (t0)         # Загружаем текущий символ
    beqz t1, remove_done
    li t2, 10           # ASCII код новой строки
    beq t1, t2, replace_newline
    addi t0, t0, 1
    j remove_loop
    
replace_newline:
    sb zero, (t0)       # Заменяем \n на \0
    
remove_done:
    # Восстанавливаем регистры
    lw ra, 12(sp)
    lw t0, 8(sp)
    lw t1, 4(sp)
    lw t2, 0(sp)
    addi sp, sp, 16
    ret

    bltz a0, file_error
    
    bltz a0, file_error

file_error:
    la a0, error_msg
    li a7, 4
    ecall
    li a7, 10
    ecall