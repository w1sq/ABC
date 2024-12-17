#include <iostream>
#include <vector>
#include <thread>
#include <mutex>
#include <random>
#include <condition_variable>

const int M = 10; // Высота сада
const int N = 10; // Ширина сада
std::vector<std::vector<int>> garden(M, std::vector<int>(N, 0));
std::mutex garden_mutex;
std::mutex start_mutex;
std::condition_variable start_cond;
bool ready_to_start = false;

void gardener1()
{
    std::unique_lock<std::mutex> lk(start_mutex);
    start_cond.wait(lk, []
                    { return ready_to_start; });
    lk.unlock();

    // Начинаем с верхнего левого угла (0,0)
    bool going_right = true;
    for (int i = 0; i < M; ++i)
    {
        if (going_right)
        {
            // Движение слева направо
            for (int j = 0; j < N; ++j)
            {
                int should_process = false;
                {
                    std::lock_guard<std::mutex> lock(garden_mutex);
                    if (garden[i][j] == 0)
                    {
                        garden[i][j] = 1;
                        should_process = true;
                    }
                }

                if (should_process)
                {
                    std::cout << "Gardener 1 processing square at (" << i << ", " << j << ")\n";
                    std::this_thread::sleep_for(std::chrono::milliseconds(100));
                }
                // Время прохождения через квадрат
                std::this_thread::sleep_for(std::chrono::milliseconds(10));
            }
        }
        else
        {
            // Движение справа налево
            for (int j = N - 1; j >= 0; --j)
            {
                int should_process = false;
                {
                    std::lock_guard<std::mutex> lock(garden_mutex);
                    if (garden[i][j] == 0)
                    {
                        garden[i][j] = 1;
                        should_process = true;
                    }
                }

                if (should_process)
                {
                    std::cout << "Gardener 1 processing square at (" << i << ", " << j << ")\n";
                    std::this_thread::sleep_for(std::chrono::milliseconds(100));
                }
                // Время прохождения через квадрат
                std::this_thread::sleep_for(std::chrono::milliseconds(10));
            }
        }
        going_right = !going_right; // Меняем направление для следующего ряда
    }
}

void gardener2()
{
    std::unique_lock<std::mutex> lk(start_mutex);
    start_cond.wait(lk, []
                    { return ready_to_start; });
    lk.unlock();

    // Начинаем с нижнего правого угла (M-1, N-1)
    bool going_left = true;
    for (int i = M - 1; i >= 0; --i)
    {
        if (going_left)
        {
            // Движение справа налево
            for (int j = N - 1; j >= 0; --j)
            {
                int should_process = false;
                {
                    std::lock_guard<std::mutex> lock(garden_mutex);
                    if (garden[i][j] == 0)
                    {
                        garden[i][j] = 2;
                        should_process = true;
                    }
                }

                if (should_process)
                {
                    std::cout << "Gardener 2 processing square at (" << i << ", " << j << ")\n";
                    std::this_thread::sleep_for(std::chrono::milliseconds(100));
                }
                // Время прохождения через квадрат
                std::this_thread::sleep_for(std::chrono::milliseconds(10));
            }
        }
        else
        {
            // Движение слева направо
            for (int j = 0; j < N; ++j)
            {
                int should_process = false;
                {
                    std::lock_guard<std::mutex> lock(garden_mutex);
                    if (garden[i][j] == 0)
                    {
                        garden[i][j] = 2;
                        should_process = true;
                    }
                }

                if (should_process)
                {
                    std::cout << "Gardener 2 processing square at (" << i << ", " << j << ")\n";
                    std::this_thread::sleep_for(std::chrono::milliseconds(100));
                }
                // Время прохождения через квадрат
                std::this_thread::sleep_for(std::chrono::milliseconds(10));
            }
        }
        going_left = !going_left; // Меняем направление для следующего ряда
    }
}

int main()
{
    // Инициализация сада с препятствиями
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<> dis(10, 30);
    int obstacles = M * N * dis(gen) / 100;
    while (obstacles > 0)
    {
        int i = dis(gen) % M;
        int j = dis(gen) % N;
        if (garden[i][j] == 0)
        {
            garden[i][j] = -1;
            --obstacles;
        }
    }
    std::cout << "Garden with obstacles:" << std::endl;
    for (const auto &row : garden)
    {
        for (int cell : row)
        {
            std::cout << cell << " ";
        }
        std::cout << std::endl;
    }

    std::thread t1(gardener1);
    std::thread t2(gardener2);

    // Signal both threads to start
    {
        std::lock_guard<std::mutex> lk(start_mutex);
        ready_to_start = true;
        start_cond.notify_all();
    }

    t1.join();
    t2.join();

    // Вывод состояния сада
    for (const auto &row : garden)
    {
        for (int cell : row)
        {
            std::cout << cell << " ";
        }
        std::cout << std::endl;
    }

    return 0;
}