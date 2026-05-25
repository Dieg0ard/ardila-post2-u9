; MASK_KB.ASM
; nasm -f bin MASK_KB.ASM -o MASK_KB.COM

[BITS 16]
[ORG 100h]

section .data

msg_mask   db "IRQ1 enmascarado (teclado deshabilitado)...$"
msg_unmask db 13,10,"IRQ1 restaurado.$"

old_imr db 0

section .text

start:

    ; guardar IMR original
    in al,21h
    mov [old_imr],al

    ; enmascarar IRQ1
    or al,00000010b
    out 21h,al

    ; mostrar mensaje
    mov ah,09h
    mov dx,msg_mask
    int 21h

    ; ====================================
    ; Retardo aproximado (~3 segundos)
    ; ====================================

    mov cx,40

outer_loop:
    mov dx,0FFFFh

inner_loop:
    dec dx
    jnz inner_loop

    loop outer_loop

    ; ====================================
    ; restaurar IMR
    ; ====================================

    mov al,[old_imr]
    out 21h,al

    ; mensaje final
    mov ah,09h
    mov dx,msg_unmask
    int 21h

    mov ax,4C00h
    int 21h