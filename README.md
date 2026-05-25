# Ardila-Post2-U9

**Arquitectura de Computadores — Unidad 9: Entrada y Salida Avanzados**  
**Post-Contenido 2 | Ingeniería de Sistemas 2026**  
**Autor:** Diego Ardila

---

## Descripción general

Este repositorio contiene la implementación de tres programas en ensamblador x86 (modo real, COM) que demuestran el manejo de interrupciones hardware en DOSBox mediante la programación directa del PIC 8259A y la Tabla de Vectores de Interrupción (IVT).

---

## Prerrequisitos

| Requisito | Detalle |
|-----------|---------|
| Software | DOSBox 0.74 o superior + NASM 2.x |
| Directorio de trabajo | `C:\U9P2\` dentro de DOSBox |
| Conocimientos previos | IVT, INT 21h AH=25h/35h, flag IF, puertos de E/S del PIC |

---

## Estructura del repositorio

```
Ardila-Post2-U9/
├── README.md
├── ISR_KB.ASM       # Paso 2: ISR personalizado para IRQ1
├── MASK_KB.ASM      # Paso 3: Enmascaramiento del IRQ1 con el IMR
├── ISR_CHAIN.ASM    # Paso 4: Encadenamiento del ISR (chaining)
├── ck1.png          # Captura Checkpoint 1
├── ck2.png          # Captura Checkpoint 2
└── ck3.png          # Captura Checkpoint 3
```

---

## Programas

### ISR_KB.ASM — ISR personalizado para IRQ1

**Propósito:** Reemplaza temporalmente el handler de INT 09h (IRQ1, teclado) con una rutina propia que detecta cada pulsación, muestra un mensaje en pantalla y restaura el handler original al completar 5 pulsaciones.

**Funcionamiento:**
1. Obtiene y guarda el vector original de INT 09h usando `INT 21h AH=35h`.
2. Instala el ISR propio (`mi_isr`) en el vector 09h usando `INT 21h AH=25h`.
3. Entra en un bucle activo hasta que el contador llega a 5.
4. Dentro del ISR: lee el scancode del puerto 60h, imprime el mensaje, incrementa el contador y envía EOI al PIC (puerto 20h) antes de ejecutar `IRET`.
5. Restaura el handler original con `CLI` + `LDS DX,[old_isr]` + `INT 21h AH=25h` y termina.

**Compilar y ejecutar:**
```
nasm -f bin ISR_KB.ASM -o ISR_KB.COM
ISR_KB
```

**Checkpoint 1:** El programa muestra `Tecla detectada por ISR propio` exactamente 5 veces y termina con `ISR restaurado. Fin del programa.`

![Checkpoint 1](ck1.png)

---

### MASK_KB.ASM — Enmascaramiento del IRQ1 con el IMR

**Propósito:** Demuestra el control directo del IMR (Interrupt Mask Register) del PIC 8259A. Enmascara el IRQ1 durante aproximadamente 3 segundos y luego lo restaura.

**Funcionamiento:**
1. Lee el valor actual del IMR desde el puerto 21h y lo preserva en la pila.
2. Activa el bit 1 del IMR (`OR AL, 02h`) y escribe en el puerto 21h, deshabilitando el IRQ1.
3. Espera ~55 ticks del timer BIOS (≈ 3 s) usando `INT 1Ah AH=00h`.
4. Restaura el IMR original desde la pila y escribe en el puerto 21h.

> Durante los 3 segundos de enmascaramiento, los scancodes se acumulan en el buffer del 8042 pero no generan interrupciones visibles. Al restaurar el IMR el sistema vuelve a comportarse normalmente.

**Compilar y ejecutar:**
```
nasm -f bin MASK_KB.ASM -o MASK_KB.COM
MASK_KB
```

**Checkpoint 2:** Las pulsaciones no producen salida mientras IRQ1 está enmascarado; al finalizar el retardo aparece `IRQ1 restaurado.`

![Checkpoint 2](ck2.png)

---

### ISR_CHAIN.ASM — Encadenamiento del ISR (Chaining)

**Propósito:** Extiende `ISR_KB.ASM` para que, después de ejecutar el código propio, llame al handler original de INT 09h en lugar de ignorarlo. Esto permite registrar teclas sin interferir con el procesamiento normal del sistema operativo (eco de DOS, buffer BIOS, etc.).

**Funcionamiento:**
1. Instala `mi_isr_chain` como handler de INT 09h (igual que en `ISR_KB.ASM`).
2. Al final del ISR propio, en lugar de enviar el EOI y ejecutar `IRET` directamente, simula una interrupción hacia el handler original:
   ```asm
   PUSHF
   CALL FAR [old_isr]   ; simula el INT original (push flags + far call)
   IRET
   ```
3. El handler original se encarga del EOI y del procesamiento estándar del teclado.

> El encadenamiento es esencial en escenarios como depuración o registro de eventos donde el ISR actúa como observador sin sustituir la funcionalidad del sistema.

**Compilar y ejecutar:**
```
nasm -f bin ISR_CHAIN.ASM -o ISR_CHAIN.COM
ISR_CHAIN
```

**Checkpoint 3:** El contador propio registra las pulsaciones y el eco de DOS sigue funcionando con normalidad, demostrando el encadenamiento correcto.

![Checkpoint 3](ck3.png)

---

## Conceptos clave

| Concepto | Descripción |
|----------|-------------|
| PIC 8259A | Controlador de interrupciones programable; IRQ1 → INT 09h (vector 0x09) |
| IMR | Registro de máscara del PIC maestro, accesible en el puerto 21h |
| EOI | Señal de fin de interrupción enviada al puerto 20h al concluir el ISR |
| IVT | Tabla en 0000:0000 con los 256 vectores de interrupción (SEG:OFF) |
| `INT 21h AH=35h` | Obtener vector de interrupción actual (ES:BX ← handler) |
| `INT 21h AH=25h` | Instalar nuevo vector de interrupción (DS:DX → handler) |
| `IRET` | Retorno de interrupción; restaura IP, CS y FLAGS |
| Chaining | Técnica para llamar al ISR anterior desde el nuevo, preservando funcionalidad |

---

## Notas de implementación

- Los tres programas son ejecutables `.COM` (origen 0x100, modo real 16 bits).
- Se preservan y restauran todos los registros modificados dentro de los ISR.
- El flag `IF` se gestiona explícitamente con `STI`/`CLI` solo donde es necesario.
- El encadenamiento usa `PUSHF + CALL FAR` para replicar el comportamiento de `INT`, ya que el handler original espera ser invocado como interrupción.
