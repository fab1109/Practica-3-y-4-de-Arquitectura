# --- MAPEO DE DIRECCIONES ---
.eqv TensionControl 0x10010000   # registro simulado en memoria
.eqv TensionEstado  0xffff0000   # keyboard control
.eqv TensionDato    0xffff0004   # keyboard data

.text
.globl main

main:

    jal controlador_tension

    # imprimir sistolica
    move $a0, $v0
    li $v0, 1
    syscall

    # salto de linea
    li $a0, 10
    li $v0, 11
    syscall

    # imprimir diastolica
    move $a0, $v1
    li $v0, 1
    syscall

    li $v0, 10
    syscall


# ---------------------------------
# controlador_tension
# ---------------------------------
controlador_tension:

    # 1. iniciar medicion
    li $t0, 1
    li $t1, TensionControl
    sw $t0, 0($t1)

# ---- ESPERAR SISTOLICA ----
esperar_sistolica:

    lw $t0, TensionEstado

    andi $t0, $t0, 1
    beq $t0, $zero, esperar_sistolica

    # leer sistolica
    lw $v0,TensionDato

# ---- ESPERAR DIASTOLICA ----
esperar_diastolica:

    lw $t0, TensionEstado

    andi $t0, $t0, 1
    beq $t0, $zero, esperar_diastolica

    # leer diastolica
    lw $v1,TensionDato

    jr $ra