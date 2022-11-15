nasm -f elf funciones.asm
g++ -Wall -no-pie funciones.o lector.cpp -m32 -o ejecutar
./ejecutar $1 $2