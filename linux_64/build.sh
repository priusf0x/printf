gcc -c linux_64/main.cpp -o  linux_64/main.o 
# gcc -D _DEBUG -c linux_64/test.cpp -o  linux_64/test.o
nasm -f elf64 linux_64/my_print.s
gcc linux_64/my_print.o linux_64/main.o linux_64/test.o -o test.out
