#include <climits>

extern "C" int my_pr1ntf(const char*, ...);

int main()
{
    my_pr1ntf("meow %x");

    return 0;
}
