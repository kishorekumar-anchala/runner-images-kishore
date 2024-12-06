// main.cpp
#include <iostream>
#include <thread>

// thread_local variable
thread_local int x = 5;

// Function that prints the thread-local variable
void printThreadLocal() {
    std::cout << "Thread-local variable x = " << x << std::endl;
}

int main() {
    std::cout << "Main thread\n";
    printThreadLocal();

    // Create two threads
    std::thread t1(printThreadLocal);
    std::thread t2(printThreadLocal);

    t1.join();
    t2.join();

    return 0;
}
