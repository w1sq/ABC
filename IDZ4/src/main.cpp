#include <mutex>
#include <vector>
#include <thread>
#include <random>
#include <fstream>
#include <sstream>
#include <iostream>
#include <condition_variable>

std::mutex garden_mutex, start_mutex;
std::condition_variable cv, start_cond;

bool ready_to_start = false;

// Function to generate a random number in a given range
int generateRandomNumber(int min, int max)
{
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<> dis(min, max);
    return dis(gen);
}

// Function to fill the garden with rocks
void fillGardenWithRocks(int garden_height, int garden_width, std::vector<std::vector<int>> &garden)
{
    int rockCount = generateRandomNumber(10, 30);
    while (rockCount > 0)
    {
        int row = generateRandomNumber(0, garden_height - 1);
        int col = generateRandomNumber(0, garden_width - 1);
        if (garden[row][col] == 0)
        {
            garden[row][col] = -1; // Place a rock
            rockCount--;
        }
    }
}

class Gardener
{
public:
    int id;
    int garden_height;
    int garden_width;
    int walking_speed;
    int working_speed;
    std::vector<std::vector<int>> &garden;

    Gardener(int id, int garden_height, int garden_width, int walking_speed, int working_speed, std::vector<std::vector<int>> &garden) : id(id), garden_height(garden_height), garden_width(garden_width), walking_speed(walking_speed), working_speed(working_speed), garden(garden) {}

    void operator()()
    {
        // Wait for the start
        {
            std::unique_lock<std::mutex> lk(start_mutex);
            start_cond.wait(lk, []
                            { return ready_to_start; });
        }

        {
            std::unique_lock<std::mutex> lk(garden_mutex);
            cv.wait(lk, []
                    { return ready_to_start; });
        }

        if (id == 1)
        {
            processGarden(0, garden_height, 1); // First gardener starts from the top
        }
        else
        {
            processGarden(garden_height - 1, -1, -1); // Second gardener starts from the bottom
        }
    }

private:
    void processGarden(int start, int end, int step)
    {
        bool reverse = false;
        if (id == 1) // First gardener moves horizontally
        {
            for (int i = start; i != end; i += step)
            {
                int j_start = reverse ? garden_width - 1 : 0;
                int j_end = reverse ? -1 : garden_width;
                int j_step = reverse ? -1 : 1;

                for (int j = j_start; j != j_end; j += j_step)
                {
                    waitAndProcess(i, j);
                }
                reverse = !reverse;
            }
        }
        else // Second gardener moves vertically
        {
            for (int j = garden_width - 1; j >= 0; j--)
            {
                int i_start = reverse ? 0 : garden_height - 1;
                int i_end = reverse ? garden_height : -1;
                int i_step = reverse ? 1 : -1;

                for (int i = i_start; i != i_end; i += i_step)
                {
                    waitAndProcess(i, j);
                }
                reverse = !reverse;
            }
        }
    }

    void waitAndProcess(int i, int j)
    {
        while (true)
        {
            std::unique_lock<std::mutex> lock(garden_mutex);
            if (garden[i][j] == 0) // Empty square
            {
                garden[i][j] = id;
                lock.unlock();
                std::cout << "Gardener " << id << " processing square at (" << i << ", " << j << ")\n";
                std::this_thread::sleep_for(std::chrono::milliseconds(working_speed));
                return;
            }
            else if (garden[i][j] == -1 || garden[i][j] > 0) // Rock or processed square
            {
                std::this_thread::sleep_for(std::chrono::milliseconds(walking_speed));
                return;
            }
            // If the square is temporarily occupied by another gardener, wait
            cv.wait(lock);
        }
        cv.notify_all();
    }
};

void printGarden(std::ostream &ofs, std::vector<std::vector<int>> &garden)
{
    for (const auto &row : garden)
    {
        for (const auto &cell : row)
        {
            ofs << (cell == -1 ? "X" : std::to_string(cell)) << " "; // X for rocks
        }
        ofs << "\n";
    }
}

int main(int argc, char *argv[])
{
    int garden_height;
    int garden_width;
    int walking_speed;
    int first_gardener_working_speed;
    int second_gardener_working_speed;
    std::string input_file;
    std::string output_file;

    if (argc == 7)
    {
        // Read all parameters from the command line
        garden_height = std::stoi(argv[1]);
        garden_width = std::stoi(argv[2]);
        walking_speed = std::stoi(argv[3]);
        first_gardener_working_speed = std::stoi(argv[4]);
        second_gardener_working_speed = std::stoi(argv[5]);
        output_file = std::string(argv[6]);
    }
    else if (argc == 2)
    {
        input_file = argv[1];
        std::ifstream ifs(input_file);
        if (!ifs.is_open())
        {
            std::cerr << "Error opening file for reading." << std::endl;
            return 1;
        }

        // Check if the file content is valid
        if (!(ifs >> garden_height >> garden_width >> walking_speed >> first_gardener_working_speed >> second_gardener_working_speed >> output_file))
        {
            std::cerr << "Error: Invalid file content. Expected 5 digits and output file name." << std::endl;
            ifs.close();
            return 1;
        }
    }
    else
    {
        std::cerr << "Usage: " << argv[0]
                  << " <garden_height> <garden_width> <walking_speed> "
                  << "<first_gardener_working_speed> <second_gardener_working_speed> <output_file>"
                  << "\nOR\n"
                  << argv[0] << " <input_file>" << std::endl;
        return 1;
    }

    std::vector<std::vector<int>> garden(garden_height, std::vector<int>(garden_width, 0)); // 0 - empty, 1 - gardener 1, 2 - gardener 2, -1 - rock

    // Fill the garden with rocks
    fillGardenWithRocks(garden_height, garden_width, garden);

    // Initialize the output file
    std::ofstream ofs(output_file);
    if (!ofs.is_open())
    {
        std::cerr << "Error opening file for writing." << std::endl;
        return 1;
    }

    // Write the initial state of the garden
    ofs << "Initial garden:\n";
    printGarden(ofs, garden);

    std::cout << "Initial garden:\n";
    printGarden(std::cout, garden);

    // Create and start gardeners
    Gardener gardener1(1, garden_height, garden_width, walking_speed, first_gardener_working_speed, garden);  // Gardener 1
    Gardener gardener2(2, garden_height, garden_width, walking_speed, second_gardener_working_speed, garden); // Gardener 2

    std::thread t1(std::ref(gardener1));
    std::thread t2(std::ref(gardener2));

    // Start the gardeners
    {
        std::lock_guard<std::mutex> lk(start_mutex);
        ready_to_start = true;
        start_cond.notify_all();
    }

    t1.join();
    t2.join();

    ofs << "Processed garden:\n";
    printGarden(ofs, garden);
    ofs.close();

    std::cout << "Processed garden:\n";
    printGarden(std::cout, garden);

    return 0;
}