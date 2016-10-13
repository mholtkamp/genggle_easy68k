if not exist "rom/" mkdir rom

ASM68K.EXE /p /o l+ source/main.asm, rom/gengle.bin, rom/gengle.sym, rom/gengle.list
rompad.exe rom/gengle.bin
