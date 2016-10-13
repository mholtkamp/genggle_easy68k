// This program will strip the first 15 bytes of the a rom assembled
// with the asm68k.exe assembler. There is probably a better, easier
// way to do this besides writing a whole new program.

#include <stdio.h>
#include <stdlib.h>

#define ARG_COUNT 2
#define ASM_HEADER_SIZE 15

int main(int argc, char** argv)
{
	FILE* pFile = 0;
	char* arRomData = 0;

	if (argc != ARG_COUNT)
	{
		printf("romfix.exe usage: \"romfix.exe rom_to_fix.bin\"");
		return 1;
	}

	pFile = fopen(argv[1], "rb");
	
	if (pFile == 0)
	{
		printf("Could not open rom to fix.");
		return 1;
	}

	fseek(pFile, 0, SEEK_END);
	unsigned int unSize = ftell(pFile);
	fseek(pFile, ASM_HEADER_SIZE, SEEK_SET);

	if (unSize <= ASM_HEADER_SIZE)
	{
		printf("Rom file too small.");
		fclose(pFile);
		return 1;
	}

	arRomData = (char*) malloc(unSize - ASM_HEADER_SIZE);
	fread(arRomData, 1, unSize, pFile);
	fclose(pFile);
	pFile = 0;

	pFile = fopen(argv[1], "wb");

	fwrite(arRomData, 1, unSize - ASM_HEADER_SIZE, pFile);
	fclose(pFile);

	free(arRomData);

	return 0;
}