#include <climits>

extern "C" int my_pr1ntf(const char*, ...);

int main()
{
    my_pr1ntf("%d %s  %x %d%%%b%c\n", -1, "love", 3802, 100, 31, 33);

    return 0;
}
