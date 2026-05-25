; ISR_KB.ASM
; nasm -f bin ISR_KB.ASM -o ISR_KB.COM

[BITS 16]
[ORG 100h]

MAX_KEYS EQU 5

section .data

contador    dw 0
ultimo      dw 0

old_off     dw 0
old_seg     dw 0

msg_tecla   db 13,10,"Tecla detectada por ISR propio$"
msg_fin     db 13,10,"ISR restaurado. Fin del programa.$"

section .text

start:

    ; guardar ISR original INT 09h
    mov ax,3509h
    int 21h

    mov [old_off],bx
    mov [old_seg],es

    ; instalar ISR propia
    push ds

    mov ax,cs
    mov ds,ax

    mov dx,mi_isr
    mov ax,2509h
    int 21h

    pop ds

principal:

    ; revisar si hubo nueva tecla
    mov ax,[contador]
    cmp ax,[ultimo]
    je .seguir

    mov [ultimo],ax

    ; imprimir mensaje FUERA de la ISR
    mov ah,09h
    mov dx,msg_tecla
    int 21h

.seguir:

    cmp word [contador],MAX_KEYS
    jl principal

    ; restaurar ISR original
    cli

    mov dx,[old_off]
    mov ds,[old_seg]

    mov ax,2509h
    int 21h

    sti

    ; restaurar DS
    push cs
    pop ds

    ; mensaje final
    mov ah,09h
    mov dx,msg_fin
    int 21h

    mov ax,4C00h
    int 21h

; ==================================================
; ISR teclado
; ==================================================

mi_isr:

    push ax
    push ds

    ; acceder a datos
    push cs
    pop ds

    ; leer scancode
    in al,60h

    ; ignorar break codes
    test al,80h
    jnz .fin

    ; incrementar contador
    inc word [contador]

.fin:

    ; EOI
    mov al,20h
    out 20h,al

    pop ds
    pop ax

    iret