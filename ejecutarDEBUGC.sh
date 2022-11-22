nasm -f elf funciones.asm
g++ -Wall -g -no-pie funciones.o lector.cpp -m32 -o ejecutar
gdb --args ejecutar $1 $2