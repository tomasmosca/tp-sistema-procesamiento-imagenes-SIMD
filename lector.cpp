#include <iostream>
#include <unistd.h>
#include <fstream>
#include <stdio.h>
#include <stdlib.h>
#include <cmath>
#include <ctime>

using std::cout;
using std::endl;
using std::ofstream;
using std::ifstream;

#pragma pack(1)

typedef int LONG;
typedef unsigned short WORD;
typedef unsigned int DWORD;

extern "C" void aclarar(unsigned char** red, unsigned char** green, unsigned char** blue, int n);
extern "C" void aclararSIMD(unsigned char** red, unsigned char** green, unsigned char** blue, int n);
extern "C" void multiplyBlend(unsigned char** red1, unsigned char** green1, unsigned char** blue1, unsigned char** red2,
unsigned char** green2, unsigned char** blue2);
extern "C" void multiplyBlendSIMD(unsigned char** red1, unsigned char** green1, unsigned char** blue1, unsigned char** red2,
unsigned char** green2, unsigned char** blue2);
extern "C" void medianFilter(unsigned char** red, unsigned char** green, unsigned char** blue, int window);
extern "C" void medianFilterSIMD(unsigned char** red, unsigned char** green, unsigned char** blue, int window);


typedef struct tagBITMAPFILEHEADER {
    WORD bfType;
    DWORD bfSize;
    WORD bfReserved1;
    WORD bfReserved2;
    DWORD bfOffBits;
} BITMAPFILEHEADER, *PBITMAPFILEHEADER;

typedef struct tagBITMAPINFOHEADER {
    DWORD biSize;
    LONG biWidth;
    LONG biHeight;
    WORD biPlanes;
    WORD biBitCount;
    DWORD biCompression;
    DWORD biSizeImage;
    LONG biXPelsPerMeter;
    LONG biYPelsPerMeter;
    DWORD biClrUsed;
    DWORD biClrImportant;
} BITMAPINFOHEADER, *PBITMAPINFOHEADER;

//RGB primer imagen
unsigned char** reds;
unsigned char** greens;
unsigned char** blues;
int rows;
int cols;

//RGB segunda imagen (para multiply blend)
unsigned char** reds1;
unsigned char** greens1;
unsigned char** blues1;
int rows1;
int cols1;

void mBlend() {
    // Multiply Blend C++
    int temp = 0;
    for (int i = rows / 513; i < rows; i++)
        for (int j = cols / 513; j < cols; j++) {
            temp = (greens[i][j] * greens1[i][j]) / 255;
            greens[i][j] = temp;
            temp = (reds[i][j] * reds1[i][j]) / 255;
            reds[i][j] = temp;
            temp = (blues[i][j] * blues1[i][j]) / 255;
            blues[i][j] = temp;
        }
}

void medianF() {
    // Average Filter C++
    int temp = 0;
    for (int i = (rows / 513) + 1; i < rows - 1; i++)
        for (int j = (cols / 513) + 1; j < cols - 1; j++) {
            temp = round(greens[i-1][j-1]+greens[i-1][j]+greens[i-1][j+1]+greens[i][j-1]+greens[i][j]+greens[i][j+1]+greens[i+1][j-1]+greens[i+1][j]+greens[i+1][j+1]) / 9;
            greens[i][j] = temp;
            temp = round(blues[i-1][j-1]+blues[i-1][j]+blues[i-1][j+1]+blues[i][j-1]+blues[i][j]+blues[i][j+1]+blues[i+1][j-1]+blues[i+1][j]+blues[i+1][j+1]) / 9;
            blues[i][j] = temp;
            temp = round(reds[i-1][j-1]+reds[i-1][j]+reds[i-1][j+1]+reds[i][j-1]+reds[i][j]+reds[i][j+1]+reds[i+1][j-1]+reds[i+1][j]+reds[i+1][j+1]) / 9;
            reds[i][j] = temp;
        }
}

void RGB_Allocate(unsigned char**& dude) {
    dude = new unsigned char*[rows];
    for (int i = 0; i < rows; i++)
        dude[i] = new unsigned char[cols];
}

bool FillAndAllocate(char*& buffer, const char* Picture, int& rows, int& cols, int& BufferSize) { //Returns 1 if executed sucessfully, 0 if not sucessfull
    std::ifstream file(Picture);

    if (file) {
        file.seekg(0, std::ios::end);
        std::streampos length = file.tellg();
        file.seekg(0, std::ios::beg);

        buffer = new char[length];
        file.read(&buffer[0], length);

        PBITMAPFILEHEADER file_header;
        PBITMAPINFOHEADER info_header;

        file_header = (PBITMAPFILEHEADER) (&buffer[0]);
        info_header = (PBITMAPINFOHEADER) (&buffer[0] + sizeof(BITMAPFILEHEADER));
        rows = info_header->biHeight;
        cols = info_header->biWidth;
        BufferSize = file_header->bfSize;
        return 1;
    }
    else {
        cout << "File" << Picture << " don't Exist!" << endl;
        return 0;
    }
}

void GetPixlesFromBMP24(unsigned char** reds, unsigned char** greens, unsigned char** blues, int end, int rows, int cols, char* FileReadBuffer) { // end is BufferSize (total size of file)
    int count = 1;
int extra = cols % 4; // The nubmer of bytes in a row (cols) will be a multiple of 4.
    for (int i = 0; i < rows; i++){
count += extra;
    for (int j = cols - 1; j >= 0; j--)
        for (int k = 0; k < 3; k++) {
                switch (k) {
                case 0:
                    reds[i][j] = FileReadBuffer[end - count++];
                    break;
                case 1:
                    greens[i][j] = FileReadBuffer[end - count++];
                    break;
                case 2:
                    blues[i][j] = FileReadBuffer[end - count++];
                    break;
                }
            }
            }
}

void WriteOutBmp24(char* FileBuffer, const char* NameOfFileToCreate, int BufferSize) {
    std::ofstream write(NameOfFileToCreate);
    if (!write) {
        cout << "Failed to write " << NameOfFileToCreate << endl;
        return;
    }
    int count = 1;
    int extra = cols % 4; // The nubmer of bytes in a row (cols) will be a multiple of 4.
    for (int i = 0; i < rows; i++){
        count += extra;
        for (int j = cols - 1; j >= 0; j--)
            for (int k = 0; k < 3; k++) {
                switch (k) {
                case 0: //reds
                    FileBuffer[BufferSize - count] = reds[i][j];
                    break;
                case 1: //green
                    FileBuffer[BufferSize - count] = greens[i][j];
                    break;
                case 2: //blue
                    FileBuffer[BufferSize - count] = blues[i][j];
                    break;
                }
                count++;
            }
            }
    write.write(FileBuffer, BufferSize);
}


int main(int argc, char** argv) {
	char* FileBuffer; int BufferSize;
    char* FileBuffer1; int BufferSize1;
	if(argc != 3) {
		cout << "Debe ingresar un archivo de lectura y el archivo de escritura" << endl;
		cout << "Use " << argv[0] << " <FILE_IN.bmp> <FILE_OUT.bmp>" << endl;
	}
    // Fill a la imagen 1
    if (!FillAndAllocate(FileBuffer, argv[1], rows, cols, BufferSize)){
		cout << "File read error" << endl; 
		return 0;
	}
	cout << "Rows: " << rows << " Cols: " << cols << endl;
    // Fill a la imagen 2 (para multiply blend)
    if (!FillAndAllocate(FileBuffer1, argv[2], rows1, cols1, BufferSize1)){
		cout << "File read error" << endl; 
		return 0;
	}
    cout << "Rows: " << rows1 << " Cols: " << cols1 << endl;

	RGB_Allocate(reds);
	RGB_Allocate(greens);
	RGB_Allocate(blues);
    RGB_Allocate(reds1);
	RGB_Allocate(greens1);
	RGB_Allocate(blues1);

	GetPixlesFromBMP24( reds, greens, blues, BufferSize, rows, cols, FileBuffer);
    GetPixlesFromBMP24( reds1, greens1, blues1, BufferSize1, rows1, cols1, FileBuffer1);

    // Inicio del timer
    std::clock_t    start;
    start = std::clock();

    // Funciones ASM
    //aclararSIMD(reds, greens, blues, 50);
    //aclarar(reds, greens, blues, 50);
    //medianFilter(reds,greens,blues, 50);
    //medianFilterSIMD(reds,greens,blues, 50);
    //multiplyBlend(reds, greens, blues, reds1, greens1, blues1);
    //multiplyBlendSIMD(reds, greens, blues, reds1, greens1, blues1);

    // Fin del timer
    std::cout << "Time: " << (std::clock() - start) / (double)(CLOCKS_PER_SEC / 1000) << " ms" << std::endl;

    // Funciones para testear en C++
    //mBlend();
    //medianF();
	WriteOutBmp24(FileBuffer, "img-resultado.bmp", BufferSize);
	return 1;
}
