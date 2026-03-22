#include <climits>

extern "C" int my_pr1ntf(const char*, ...);

int main()
{
    my_pr1ntf("meow %x", 0x12ab);

    return 0;
}
