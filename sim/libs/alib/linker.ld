MEMORY{

    ram : ORIGIN = 0x00000000, LENGTH = 0x00002000

}
 
SECTIONS{
    .text : {
/*
        *(.init)
        *(.fini)
        *(.ctors)
        *(.dtors)
        *(.jcr)
        *(.sdata)
        *(.eh_frame)
*/
        *(.text)
    } > ram
    
    .data : {
        *(.data)
    } > ram
    
    .rodata : {
        *(.rodata)
        *(.rodata.*)
    } > ram
    
    .bss : {
        *(.bss)
    } > ram
}

/* ENTRY (_start)  */
