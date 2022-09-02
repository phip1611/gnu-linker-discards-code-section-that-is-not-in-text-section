BOOT_CODE_ADDR=0x0000000000800000
KERNEL_ADDR=0xffffffff88000000

build:
	gcc -c main.c -o main.o
	gcc -c start.S -o start.o
	ld -o c_kernel -T link.ld main.o start.o

check_elf: | check_elf_objdump check_elf_readelf

check_elf_objdump: | build
	# verify code from assembly file is linked (properly) into ELF file
	objdump -DSC c_kernel | grep "800000 <entry_asm>:"
	# verify code from high level language is linked (properly) into ELF file
	objdump -DSC c_kernel | grep "ffffffff88000000 <entry_highlevel_lang>:"

check_elf_readelf: | build
	# 1. CHECK BOOT CODE (ASSEMBLY))
	# 								   virtual address          rights       align
	readelf -Wl c_kernel | grep LOAD | grep $(BOOT_CODE_ADDR) | grep "R E" | grep 0x1000
	#                            must be in first segment
	readelf -Wl c_kernel | grep "00" | grep ".init_asm"
	# ------------------------------------------------------------------------------------------
	# 2. CHECK KERNEL CODE (HIGH LEVEL LANGUAGE)
	readelf -Wl c_kernel | grep LOAD | grep $(KERNEL_ADDR) | grep "R E" | grep 0x1000
	#                            must be in first segment
	readelf -Wl c_kernel | grep "01" | grep ".text"