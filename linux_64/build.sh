gcc -D _DEBUG -ggdb3 -std=c++23 -O2 -Wall -Wextra -Weffc++ -Waggressive-loop-optimizations\
		 -Wc++14-compat -Wmissing-declarations -Wcast-align -Wcast-qual -Wchar-subscripts\
		 -Wconditionally-supported -Wconversion -Wctor-dtor-privacy -Wempty-body -Wfloat-equal\
		 -Wformat-nonliteral -Wformat-security -Wformat-signedness -Wformat=2 -Winline -Wlogical-op\
		 -Wnon-virtual-dtor -Wopenmp-simd -Woverloaded-virtual -Wpacked -Wpointer-arith -Winit-self\
		 -Wredundant-decls -Wshadow -Wsign-conversion -Wsign-promo -Wstrict-null-sentinel\
		 -Wstrict-overflow=2 -Wsuggest-attribute=noreturn -Wsuggest-final-methods\
		 -Wsuggest-final-types -Wsuggest-override -Wswitch-default -Wswitch-enum -Wsync-nand\
		 -Wundef -Wunreachable-code -Wunused -Wuseless-cast -Wvariadic-macros -Wno-literal-suffix\
		 -Wno-missing-field-initializers -Wno-narrowing -Wno-old-style-cast -Wno-varargs -Wstack-protector\
		 -fcheck-new -fsized-deallocation -fstack-protector -fstrict-overflow -fno-omit-frame-pointer -Werror=vla \
               -c linux_64/main.cpp -o  linux_64/main.o

nasm -f elf64 linux_64/my_print.s
gcc -no-pie -o test.out linux_64/main.o linux_64/my_print.o 
