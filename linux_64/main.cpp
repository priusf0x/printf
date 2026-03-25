#include <climits>
#include <stdio.h>

extern "C" int my_pr1ntf(const char*, ...);

int main()
{

    my_pr1ntf("%f %f %f %f %f %f %f\n", 
                -143240.034324,
                -11.034324,
                -12.034324,
                13.034324,
                -14.034324,
                -0.02,
                -16.034324
                );


    // #include "../test.h"

    my_pr1ntf("%d %s  %x %d%%%b%c\n", -1, "love", 3802, 100, 31, 33);
    my_pr1ntf("%o\n", 312312);
    my_pr1ntf("meow %x\n", 0xFFFFFFFFFFFFaFFF);
    my_pr1ntf("meow %d %s\n", 124123, "hellloooooo!");
    my_pr1ntf("%s meeeow\n",  "312312312");
    my_pr1ntf("motya %cosa%c\n%d %s %x %d%%%b%c\n", 's',  'l', -1, "love", 3802, 100, 31, 33);
    my_pr1ntf("%d\n", INT_MAX);

    return 0;
}
