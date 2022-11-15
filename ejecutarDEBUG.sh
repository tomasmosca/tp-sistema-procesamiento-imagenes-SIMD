nasm -f elf -g funciones.asm
g++ -Wall -no-pie funciones.o lector.cpp -m32 -o ejecutar
gdb --args ejecutar $1 $2