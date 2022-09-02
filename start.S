# start symbol must be globally available (linker must find it, don't discard it)
.GLOBAL entry_asm

.EXTERN entry_highlevel_lang

.section .text.boot

    # Entry referenced by the ELF file
    entry_asm:
        movabs $0xdeadbeef, %r15
        jmp entry_highlevel_lang
        ud2
