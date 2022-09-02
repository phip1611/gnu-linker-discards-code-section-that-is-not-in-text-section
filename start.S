# start symbol must be globally available (linker must find it, don't discard it)
.GLOBAL entry_asm

.EXTERN entry_highlevel_lang

// "ax": section flags:
// https://ftp.gnu.org/old-gnu/Manuals/gas-2.9.1/html_chapter/as_7.html
//
// VERY important if you want to use custom names for your sections in
// the linking process.
.section .lol, "ax"

    # Entry referenced by the ELF file
    entry_asm:
        movabs $0xdeadbeef, %r15
        jmp entry_highlevel_lang
        ud2
