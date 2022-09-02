/*
 * Custom linker script that ensures that boot code (written in assembly) and code from high
 * level language (.text section) are placed in different segments.
 */

/* Symbol comes from start.S */
ENTRY(entry_asm)

PHDRS
{
    /* PT_LOAD FLAGS(5): The flags of an ELF program header. Always 32 bit long, also for
       64-bit ELFs. Also called "Segment Permissions" in ELF specification or "p_flags". */
    init_asm     PT_LOAD FLAGS(5); /* 0b101 */
    kernel_rx    PT_LOAD FLAGS(5); /* 0b101 */
}

SECTIONS {

    .init_asm 8M :
    {
        *(.lol);
    } : init_asm

    .text 0xffffffff88000000 : ALIGN(4K)
    {
        *(.text .text.*)
    } : kernel_rx

    /DISCARD/ : {
      *(.comment .comment.*)
      *(.eh_frame)
    }

}
