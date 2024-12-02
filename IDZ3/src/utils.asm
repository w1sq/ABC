.globl process_files
.globl remove_newline
.globl reverse_file
.globl file_error
.globl filename_in
.globl filename_out

.data
    error_msg: .string "Ошибка при работе с файлом\n"
    error_input: .string "Ошибка: входной файл не существует: "
    error_output: .string "Ошибка: не удалось создать выходной файл: "
    newline: .string "\n"
    filename_in:  .space 256    # Буфер для имени входного файла
    filename_out: .space 256    # Буфер для имени выходного файла

.text
# Подпрограмма обработки файлов
process_files:
    # Сохраняем используемые регистры
    addi sp, sp, -24
    sw ra, 20(sp)
    sw t3, 16(sp)    # для дескриптора входного файла
    sw t4, 12(sp)    # для размера файла
    sw t5, 8(sp)     # для дескриптора выходного файла
    sw t0, 4(sp)     # для текущей позиции
    sw t1, 0(sp)     # для сравнения Y/N
    
    # Открытие входного файла
    la a0, filename_in
    li a1, 0         # открываем для чтения
    li a7, 1024
    ecall
    bltz a0, input_error
    mv t3, a0
    
    # Получение размера файла
    mv a0, t3
    li a1, 0
    li a2, 2         # SEEK_END
    li a7, 62
    ecall
    mv t4, a0        # сохраняем размер
    
    # Возвращаемся в начало файла
    mv a0, t3
    li a1, 0
    li a2, 0         # SEEK_SET
    li a7, 62
    ecall
    
    # Открытие выходного файла
    la a0, filename_out
    li a1, 1         # открываем для записи
    li a7, 1024
    ecall
    bgez a0, file_opened  # если файл открылся успешно
    
    # Создаем файл, если его нет
    la a0, filename_out
    li a1, 1         # создаем для записи
    li a2, 0x1FF     # права доступа (777 в восьмеричной системе)
    li a7, 1024      # системный вызов для создания файла
    ecall
    bltz a0, output_error
    
file_opened:
    mv t5, a0
    
    # Делаем реверс файла
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
    lw ra, 20(sp)
    lw t3, 16(sp)
    lw t4, 12(sp)
    lw t5, 8(sp)
    lw t0, 4(sp)
    lw t1, 0(sp)
    addi sp, sp, 24
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
    lw ra, 12(sp)
    lw t0, 8(sp)
    lw t1, 4(sp)
    lw t2, 0(sp)
    addi sp, sp, 16
    ret

file_error:
    la a0, error_msg
    li a7, 4
    ecall
    li a7, 10
    ecall

input_error:
    la a0, error_input
    li a7, 4
    ecall
    
    # Выводим имя файла, который не удалось открыть
    la a0, filename_in
    li a7, 4
    ecall
    
    la a0, newline
    li a7, 4
    ecall
    
    li a7, 10
    ecall

output_error:
    la a0, error_output
    li a7, 4
    ecall
    
    # Выводим имя файла, который не удалось создать
    la a0, filename_out
    li a7, 4
    ecall
    
    la a0, newline
    li a7, 4
    ecall
    
    li a7, 10
    ecall