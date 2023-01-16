# Minimal Reproducible Example: GNU Linker (ld) Discards Code That Is Not In Text Section

**UPDATE**
This is not a bug but expected behavior. After some research, I created the following 
blogposts:
- <https://phip1611.de/blog/linking-bss-into-data-to-ensure-the-mem-size-equals-file-size-for-each-load-segment-bss-in-a-progbits-section/>
- <https://phip1611.de/blog/how-does-the-file-size-is-smaller-than-mem-size-optimization-work-in-gnu-ld/>

**Orignal Content**

This repository shows a minimal reproducible example of a strange behavior of the GNU linker (ld)
and a weird interaction with GNU Assembler (as). A full write-up can be found on [my blog](https://phip1611.de/blog/gnu-ld-discards-section-containing-code-a-bug-hunting-story/).

My goal was to create an ELF file for a kernel that looks like this:
```
Elf file type is EXEC (Executable file)
Entry point 0x800000
There are 2 program headers, starting at offset 64

Program Headers:
  Type           Offset   VirtAddr           PhysAddr           FileSiz  MemSiz   Flg Align
  LOAD           0x001000 0x0000000000800000 0x0000000000800000 0x000011 0x000011 R E 0x1000
  LOAD           0x002000 0xffffffff88000000 0xffffffff88000000 0x00000f 0x00000f R E 0x1000

 Section to Segment mapping:
  Segment Sections...
   00     .init_asm 
   01     .text 

```

I need two load segments. Inside the segment containing the `.text` section(s), I want the compiled 
x86_64 code from a high-level language that uses 64-bit virtual addresses. Inside the `.init_asm` 
segment, I want code that is relevant for bootstrapping the x86_64 CPU: A mixture of 16 bit, 32 bit,
and 64 bit code. This requires an assembly source file and a high level language (such as C) file 
at minimum.

The assembly is supposed to work like this:
```text
.section .boot

    # bootloader hands off execution to this function
    entry_asm:
        # do stuff; bring CPU into 64-bit long mode
        movabs $0xdeadbeef, %r15
        # jump into high-level code
        jmp entry_highlevel_lang
        ud2
```

The linker file (excerpt) looks like this:
```
/* ... */
SECTIONS {

    /* Boot code */
    .init_asm 8M :
    {
        *(.boot);
    } : init_asm

    /* High-Level code */
    .text 0xffffffff88000000 : ALIGN(4K)
    {
        *(.text .text.*)
    } : kernel_rx

    /* ... */
}
```

However, the resulting ELF file always **did not** contain the boot code of the `*(.boot)` section.
Even with linker directives such as `KEEP();` or linker arguments such as `--no-gc-sections` 
and `--whole-archive`. The assembly code always ended up in the file (verified with `objdump -d`) 
but its address was garbage (address 0); there was no section assigned to it. 
Also, very experienced colleagues with years of experience could not find the issue in my linker 
scripts. We spend a few hours on this. We thought about bugs in `readelf`, in the GNU linker, tried
multiple versions of those tools.. but in the end:

In short, our findings are the following:
1) If you write `.section .boot` in the assembly file, the symbol is discarded, whatever you do. [44441346b3049807fc1d1299761eb734ec7c08cd](https://github.com/phip1611/gnu-linker-discards-code-section-that-is-not-in-text-section/commit/44441346b3049807fc1d1299761eb734ec7c08cd)
2) If you name the section `.section .init`, it is working magically (wtf?!) [e6a894e1c8eae66a713de4d61cf7ccb0dc41d92c](https://github.com/phip1611/gnu-linker-discards-code-section-that-is-not-in-text-section/commit/e6a894e1c8eae66a713de4d61cf7ccb0dc41d92c)
3) If you name the section `.section .text.boot` and adjust the linker script with `*(.text.boot);`
   accordingly, it works as well. [05eb6a22c3baeea11176b58784f920119a1e326e](https://github.com/phip1611/gnu-linker-discards-code-section-that-is-not-in-text-section/commit/05eb6a22c3baeea11176b58784f920119a1e326e)
4) If you want to use arbitrary names, you must write `.section .foo, "ax"` in the assembly file.
   `, "ax"` does the trick (wtf²) [89b19a30bf0a50bf86203afcf70a2dbba823fbb2](https://github.com/phip1611/gnu-linker-discards-code-section-that-is-not-in-text-section/commit/89b19a30bf0a50bf86203afcf70a2dbba823fbb2)

We really do not understand 4). We found some documentation that says what it does but not why it 
is required. Marking code as execute in assembly feels wrong. Why does a compiler needs to 
know that? This should be only important to the linker.. If you know a reason for this, please let 
me know!

