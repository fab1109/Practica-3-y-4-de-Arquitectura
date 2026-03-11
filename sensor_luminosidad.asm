.data
    # Registros del sensor 
    LuzControl: .word 0     # Escribir 0x1 inicializa
    LuzEstado:  .word 0     # 0: no listo, 1: listo, -1: error
    LuzDatos:   .word 123    # Valor 0-1023

    msg_resultado:  .asciiz "\n[LECTURA] Valor: "
    msg_status:     .asciiz " | Estado de retorno: "

.text
.globl main

main:
    # --- LLAMADA A PROCEDIMIENTOS ---
    jal InicializarSensorLuz
    jal LeerLuminosidad

    # Guardar resultados
    move $t8, $v0
    move $t9, $v1

    # --- MOSTRAR RESULTADOS ---
    li $v0, 4
    la $a0, msg_resultado
    syscall
    move $a0, $t8
    li $v0, 1
    syscall

    li $v0, 4
    la $a0, msg_status
    syscall
    move $a0, $t9
    li $v0, 1
    syscall

    li $v0, 10
    syscall

# --- PROCEDIMIENTOS ---

InicializarSensorLuz:
    li $t0, 1
    la $t1, LuzControl
    sw $t0, 0($t1)      # Escribir 0x1 para inicializar

EsperarSensor:
    la $t1, LuzEstado
    lw $t2, 0($t1)
    # Espera mientras el estado sea exactamente 0 (no listo)
    beq $t2, $zero, EsperarSensor 
    jr $ra

LeerLuminosidad:
    la $t1, LuzEstado
    lw $t2, 0($t1)      
    
    li $t4, -1
    beq $t2, $t4, RetornoError # Si es -1, código de error
    
    # Caso éxito (Estado es 1)
    la $t1, LuzDatos
    lw $v0, 0($t1)      # $v0 = valor (0-1023)
    li $v1, 0           # $v1 = 0 (lectura correcta)
    jr $ra

RetornoError:
    li $v0, 0           
    li $v1, -1          # $v1 = -1 (error)
    jr $ra
