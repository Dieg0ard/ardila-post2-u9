; ISR_CHAIN.ASM
; Encadenamiento de ISR de teclado INT 09h
;
; Compilar:
; nasm -f bin ISR_CHAIN.ASM -o ISR_CHAIN.COM

[BITS 16]
[ORG 100h]

MAX_KEYS EQU 5

section .data

contador    dw 0
ultimo      dw 0

old_isr     dd 0

msg_tecla   db 13,10,"Tecla registrada por ISR encadenada$"
msg_fin     db 13,10,"ISR restaurado. Fin del programa.$"

section .text

start:

    ; ==========================================
    ; Guardar handler original INT 09h
    ; ==========================================

    mov ax,3509h
    int 21h

    mov [old_isr],bx
    mov [old_isr+2],es

    ; ==========================================
    ; Instalar nueva ISR
    ; ==========================================

    push ds

    mov ax,cs
    mov ds,ax

    mov dx,mi_isr_chain

    mov ax,2509h
    int 21h

    pop ds

; ==========================================
; Bucle principal
; ==========================================

main_loop:

    ; ¿hubo nueva tecla?
    mov ax,[contador]
    cmp ax,[ultimo]
    je .seguir

    mov [ultimo],ax

    ; imprimir mensaje
    mov ah,09h
    mov dx,msg_tecla
    int 21h

.seguir:

    cmp word [contador],MAX_KEYS
    jl main_loop

; ==========================================
; Restaurar ISR original
; ==========================================

    cli

    lds dx,[old_isr]

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
; ISR encadenada
; ==================================================

mi_isr_chain:

    push ax
    push ds

    ; acceder a datos
    push cs
    pop ds

    ; leer scancode del teclado
    in al,60h

    ; ignorar break codes
    test al,80h
    jnz .chain

    ; incrementar contador
    inc word [contador]

.chain:

    pop ds
    pop ax

    ; ==========================================
    ; Encadenar con ISR original
    ; simular INT:
    ; PUSHF + FAR CALL
    ; ==========================================

    pushf
    call far [old_isr]

    iret