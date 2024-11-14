import math


def calculate_pi(epsilon):
    """
    Вычисляет значение π с заданной точностью через дзета-функцию Римана ζ(2)
    :param epsilon: требуемая точность
    :return: приближенное значение π
    """
    if epsilon <= 0:
        raise ValueError("Точность должна быть положительной")

    # Вычисляем ζ(2) как сумму ряда 1/n²
    zeta_2 = 0
    n = 1

    # Оценка необходимого количества членов ряда
    # Используем более точную оценку, учитывая, что π² = 6 * ζ(2)
    max_terms = int(2 / (epsilon * math.sqrt(6)))

    for _ in range(max_terms):
        term = 1 / (n * n)
        zeta_2 += term
        n += 1

    # π² = 6 * ζ(2)
    pi = math.sqrt(6 * zeta_2)
    return pi


def run_tests():
    """Запускает автоматические тесты с разными значениями точности"""
    test_epsilons = [0.1, 0.01, 0.001, 0.0001]
    pi_const = math.pi

    for i, epsilon in enumerate(test_epsilons, 1):
        print(f"\nТест #{i}")
        print(f"Точность: {epsilon}")

        try:
            calculated_pi = calculate_pi(epsilon)
            print(f"Вычисленное значение π = {calculated_pi}")

            # Проверяем относительную погрешность
            error = abs(calculated_pi - pi_const) / pi_const
            if error < epsilon:
                print("Тест пройден успешно")
            else:
                print("Тест не пройден")

        except ValueError as e:
            print(f"Ошибка: {e}")


def main():
    while True:
        print("\nВыберите режим (1 - ручной ввод точности, 2 - автотест): ", end="")
        mode = input()

        if mode == "1":
            try:
                epsilon = float(
                    input("Введите точность вычисления (например, 0.001): ")
                )
                pi = calculate_pi(epsilon)
                print(f"Вычисленное значение π = {pi}")
            except ValueError as e:
                print(f"Ошибка: {e}")
        elif mode == "2":
            run_tests()
            break
        else:
            print("Неверный режим, попробуйте снова")


if __name__ == "__main__":
    main()
