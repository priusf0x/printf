gcc -D _DEBUG -c linux_64/main.cpp -o  linux_64/main.o

nasm -f elf64 linux_64/my_print.s
gcc -no-pie -o test.out linux_64/main.o linux_64/my_print.o 
