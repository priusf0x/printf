#include <climits>

extern "C" int my_pr1ntf(const char*, ...);

int main()
{
    my_pr1ntf("meow %s",  "312312312");

    return 0;
}
