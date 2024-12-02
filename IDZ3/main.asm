.data
    filename_in:  .space 256    # Буфер для имени входного файла
    filename_out: .space 256    # Буфер для имени выходного файла
    prompt_in:   .string "Введите имя входного файла: "
    prompt_out:  .string "Введите имя выходного файла: "
    error_msg:   .string "Ошибка при работе с файлом\n"

.text
.globl main
main:
    # Запрос имени входного файла
    la a0, prompt_in
    li a7, 4
    ecall
    
    # Чтение имени входного файла
    la a0, filename_in
    li a1, 256
    li a7, 8
    ecall
    
    # Удаление символа новой строки из имени файла
    la a0, filename_in    # Передаем адрес строки в a0
    jal remove_newline
    
    # Запрос имени выходного файла
    la a0, prompt_out
    li a7, 4
    ecall
    
    # Чтение имени выходного файла
    la a0, filename_out
    li a1, 256
    li a7, 8
    ecall
    
    # Удаление символа новой строки
    la a0, filename_out   # Передаем адрес строки в a0
    jal remove_newline
    
    # Открытие входного файла для чтения
    la a0, filename_in
    li a1, 0        # Режим чтения
    li a7, 1024
    ecall
    
    # Сохранение дескриптора входного файла
    mv s0, a0
    
    # Получение размера файла
    mv a0, s0
    li a1, 0        # Смещение 0
    li a2, 2        # SEEK_END = 2
    li a7, 62       # lseek
    ecall
    
    mv s1, a0       # Сохраняем размер файла
    
    # Открытие выходного файла для записи
    la a0, filename_out
    li a1, 1        # Режим записи
    li a7, 1024     # open
    ecall
    
    # Проверка на ошибку открытия файла
    bltz a0, file_error
    
    # Сохранение дескриптора выходного файла
    mv s2, a0
    
    # Выделяем место на стеке только для ОДНОГО символа
    addi sp, sp, -1

    # Начинаем с последнего символа
    addi s1, s1, -1     # Размер - 1 = индекс последнего символа
    mv t0, s1           # t0 = текущая позиция для чтения

read_loop:
    # Выходим если дошли до начала файла
    bltz t0, done
    
    # Устанавливаем позицию для чтения
    mv a0, s0           # Дескриптор входного файла
    mv a1, t0           # Текущая позиция
    li a2, 0           # SEEK_SET = 0
    li a7, 62          # lseek
    ecall
    
    # Читаем один символ
    mv a0, s0
    mv a1, sp          # Адрес для одного символа
    li a2, 1           # Читаем 1 байт
    li a7, 63          # read
    ecall
    
    # Записываем символ в выходной файл
    mv a0, s2          # Дескриптор выходного файла
    mv a1, sp          # Адрес символа
    li a2, 1           # Пишем 1 байт
    li a7, 64          # write
    ecall
    
    # Переходим к предыдущему символу
    addi t0, t0, -1
    j read_loop

done:
    # Восстанавливаем стек
    addi sp, sp, 1

    # Закрываем файлы
    mv a0, s0
    li a7, 57
    ecall
    
    mv a0, s2
    li a7, 57
    ecall
    
    # Завершение программы
    li a7, 10
    ecall

# Функция для удаления символа новой строки из строки
remove_newline:
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
    ret

    bltz a0, file_error
    
    bltz a0, file_error

file_error:
    la a0, error_msg
    li a7, 4
    ecall
    li a7, 10
    ecall