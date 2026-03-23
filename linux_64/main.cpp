#include <climits>
#include <stdio.h>

extern "C" int my_pr1ntf(const char*, ...);

int main()
{
    #include "../test.h"


    // my_pr1ntf("%d %s  %x %d%%%b%c\n", -1, "love", 3802, 100, 31, 33);
    // my_pr1ntf("%o\n", 312312);
    // my_pr1ntf("meow %x\n", 0x12ab);
    // my_pr1ntf("meow %d %s\n", 124123, "hellloooooo!");
    // my_pr1ntf("%s meeeow\n",  "312312312");
    // my_pr1ntf("motya %cosa%c\n%d %s %x %d%%%b%c\n", 's',  'l', -1, "love", 3802, 100, 31, 33);
    // my_pr1ntf("%d\n", 0xFFAFFFFFAFAFAF);

    return 0;
}
