.data
    # Mapa de E/S en memoria para el sensor de presión
    PresionControl: .word 0
    PresionEstado:  .word 1   # 0: no listo, 1: listo, -1: error
    PresionDatos:   .word 123

    msg_res_dat:    .asciiz "\n-> Valor de Presion: "
    msg_res_est:    .asciiz " | Codigo de Estado devuelto: "

.text
.globl main

main:
    # --- EJECUTAR PROCEDIMIENTOS ---
    jal InicializarSensorPresion
    jal LeerPresion

    # Guardar los valores que retornó LeerPresion ($v0 y $v1)
    move $t8, $v0       # Valor de la presión
    move $t9, $v1       # Código de estado (0 o -1)

    # --- 4. MOSTRAR RESULTADOS ---
    li $v0, 4
    la $a0, msg_res_dat
    syscall
    li $v0, 1
    move $a0, $t8
    syscall

    li $v0, 4
    la $a0, msg_res_est
    syscall
    li $v0, 1
    move $a0, $t9
    syscall

    # Terminar el programa
    li $v0, 10
    syscall


# PROCEDIMIENTOS

InicializarSensorPresion:
    li   $t0, 5
    la   $t1, PresionControl
    sw   $t0, 0($t1)        # Escribir 0x5 en Control para inicializar
    jr   $ra

LeerPresion:
    addi $sp, $sp, -4    
    sw   $ra, 0($sp)
    li   $t2, 0             # Bandera de reintento (0 = no reintentado)

esperar:
    la   $t1, PresionEstado
    lw   $t0, 0($t1)        # Leemos el estado del sensor
    
    beqz $t0, esperar       # Si es 0 (no listo): sigue esperando
    bgtz $t0, exito         # Si es > 0 (es 1): lectura válida, salto a éxito
    
    # Si llega a esta línea, el estado es -1 (Error)
    bnez $t2, fallo_final   # Si $t2 ya no es 0, ya reintentamos. Fin.
    li   $t2, 1             # Marcamos que hacemos el reintento único
    jal  InicializarSensorPresion
    j    esperar            # Volvemos a leer

exito:
    la   $t1, PresionDatos
    lw   $v0, 0($t1)        # Retorna el valor leído en $v0
    li   $v1, 0             # Retorna código de estado 0 en $v1
    j    salir

fallo_final:
    li   $v0, 0             # Valor irrelevante en caso de fallo
    li   $v1, -1            # Retorna código de error -1 en $v1

salir:
    lw   $ra, 0($sp)      
    addi $sp, $sp, 4
    jr   $ra
