#include <stdio.h>
#include <unistd.h>


void aclarar(unsigned char** red, unsigned char** green, unsigned char** blue, int n);
void medianFilter(unsigned char** red,unsigned char** green, unsigned char** blue, int window);
void multiplyBlend(unsigned char** red1, unsigned char** green1, unsigned char** blue1, unsigned char** red2,
unsigned char** green2, unsigned char** blue2);

typedef struct  tagBITMAPFILEHEADER
{
    unsigned short bfType;
    unsigned int bfsize;
    unsigned short bfReserved1;
    unsigned short bfReserved2;
    unsigned int bfOffBitts;
} BITMAPFILEHEADER, *BITMAPFILEHEADER;

typedef struct tagBIPMAPINFOHEADER
{
    unsigned int biSize;
    long biWidth;
    long biHeight;
    unsigned short biPlanes;
    unsigned short biBitCount;
    unsigned int biCompression;
    unsigned int biSizeImage;
    long biXPelsPerMeter;
    long biYPelsPerMeter;
    unsigned int biClrUsed;
    unsigned int biClrImportant;
}BIPMAPINFOHEADER, *BIPMAPINGOHEADER;

unsigned char** reds;
unsigned char** greens;
unsigned char** blues;
int rows;
int cols;

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

int main(int argc, char **argv){
    char* FileBuffer; int BufferSize;
	RGB_Allocate(reds);
	RGB_Allocate(greens);
	RGB_Allocate(blues);
	GetPixlesFromBMP24( reds, greens, blues, BufferSize, rows, cols, FileBuffer);
	ColorTest();
	WriteOutBmp24(FileBuffer, argv[2], BufferSize);
	return 1;
}