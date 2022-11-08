#include <iostream>
#include <unistd.h>
#include <fstream>

using std::cout;
using std::endl;
using std::ofstream;
using std::ifstream;

#pragma pack(1)

typedef int LONG;
typedef unsigned short WORD;
typedef unsigned int DWORD;

void aclarar(unsigned char** red, unsigned char** green, unsigned char** blue, int n);
void medianFilter(unsigned char** red, unsigned char** green, unsigned char** blue, int window);
void multiplyBlend(unsigned char** red1, unsigned char** green1, unsigned char** blue1, unsigned char** red2,
unsigned char** green2, unsigned char** blue2);


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

unsigned char** reds;
unsigned char** greens;
unsigned char** blues;
int rows;
int cols;

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
	if(argc != 3) {
		cout << "Debe ingresar un archivo de lectura y el archivo de escritura" << endl;
		cout << "Use " << argv[0] << " <FILE_IN.bmp> <FILE_OUT.bmp>" << endl;
	}
	if (!FillAndAllocate(FileBuffer, argv[1], rows, cols, BufferSize)){
		cout << "File read error" << endl; 
		return 0;
	}
	cout << "Rows: " << rows << " Cols: " << cols << endl;
	RGB_Allocate(reds);
	RGB_Allocate(greens);
	RGB_Allocate(blues);
	GetPixlesFromBMP24( reds, greens, blues, BufferSize, rows, cols, FileBuffer);
	WriteOutBmp24(FileBuffer, argv[2], BufferSize);
	return 1;
}