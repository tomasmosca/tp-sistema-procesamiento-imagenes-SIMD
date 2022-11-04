#include <stdio.h>

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