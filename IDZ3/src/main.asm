.include "macros.asm"
.include "utils.asm"

.data
    prompt_in:   .string "Введите имя входного файла: "
    prompt_out:  .string "Введите имя выходного файла: "
    console_prompt: .string "Вывести результат на консоль? (Y/N): "
    buffer:        .space 2     # Для ответа Y/N

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
    
    # Спрашиваем про вывод на консоль
    print_str(console_prompt)
    
    # Читаем ответ
    read_str(buffer, 2)
    
    # Проверяем ответ
    lb t0, buffer
    li t1, 'Y'
    beq t0, t1, print_to_console
    li t1, 'y'
    beq t0, t1, print_to_console
    j end_program

print_to_console:
    # Открываем выходной файл для чтения
    open_file(filename_out, 0)  # 0 - режим чтения
    bltz a0, end_program
    mv s0, a0        # сохраняем дескриптор
    
    # Выделяем буфер для чтения
    addi sp, sp, -256
    mv s1, sp        # сохраняем адрес буфера
    
read_and_print:
    # Читаем из файла
    read_file(s0, s1, 255)
    
    beqz a0, cleanup # если достигнут конец файла
    
    # Выводим на консоль
    mv a1, a0        # сохраняем количество прочитанных байт
    mv a0, s1
    li a7, 4
    ecall
    
    j read_and_print

cleanup:
    # Закрываем файл
    close_file(s0)
    
    # Освобождаем буфер
    addi sp, sp, 256

end_program:
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
    print_str(prompt_in)
    read_str(filename_in, 256)
    
    # Удаление \n из входного имени
    la a0, filename_in
    jal remove_newline
    
    # Запрос имени выходного файла
    print_str(prompt_out)
    read_str(filename_out, 256)
    
    # Удаление \n из выходного имени
    la a0, filename_out
    jal remove_newline
    
    lw ra, 0(sp)
    addi sp, sp, 4
    ret