.data
    buffer:      .space 10
    BUFFER_SIZE: .word 10
    indice:      .word 0
    men1:        .asciiz "\nContenido del Buffer (20s): "
    espacio:     .asciiz " "

.text
.globl main

main:
    # 1. Habilitar interrupciones en el Teclado (Bit 1 = Interrupt Enable)
    li $t0, 2
    sw $t0, 0xffff0000       #registro de control del teclado.

    # 2. Habilitar interrupciones en el CPU (Coprocesador 0)
    mfc0 $a0, $12            # Leer registro Status
    ori  $a0, $a0, 0x801     # Habilitar Interrupciones Globales y nivel de Teclado
    mtc0 $a0, $12            #Devolver el valor modificado al CP0

ciclo_principal:
    # Limpiar buffer para la nueva ronda
    la $t0, buffer
    li $t1, 0
limpiar_b:
    sb $zero, 0($t0)
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    blt $t1, 10, limpiar_b
    sw $zero, indice

    # Guardar tiempo inicial
    li $v0, 30
    syscall
    move $s1, $a0            # Tiempo de inicio

# ==============================
# BUCLE DE ESPERA PASIVA
# ==============================
esperar_20s:
    li $v0, 30
    syscall
    sub $t9, $a0, $s1
    blt $t9, 20000, esperar_20s # El main solo mira el reloj

# ==============================
# IMPRESIÓN DE RESULTADOS
# ==============================
    li $v0, 4
    la $a0, men1
    syscall

    li $t2, 0
imprimir:
    lw $t7, BUFFER_SIZE
    beq $t2, $t7, ciclo_principal
    la $t6, buffer
    add $t6, $t6, $t2
    lb $a0, 0($t6)
    
    beqz $a0, saltar
    li $v0, 11
    syscall
    li $v0, 4
    la $a0, espacio
    syscall
saltar:
    addi $t2, $t2, 1
    j imprimir

# ==============================================================
# SECCIÓN DE KERNEL (Manejador de Interrupciones)
# ==============================================================
.ktext 0x80000180          # Dirección fija de memoria donde MIPS busca el manejador

    # 1. PROTECCIÓN DE REGISTROS
    .set noat              # Le dice al ensamblador: "No uses el registro $at"
    move $k0, $at          # Salvamos el valor de $at en $k0 (registro de kernel)
    .set at                # Restauramos el uso normal de $at

    # 2. IDENTIFICACIÓN Y LECTURA DEL DATO
    # En un sistema real, aquí preguntaríamos al registro "Cause" qué pasó.
    # Como solo activamos el teclado, asumimos que es una interrupción de teclado.
    
    lw $k1, 0xffff0004     # LEER DATO: Accedemos al registro de datos del teclado
                           # Al leer esta dirección, el hardware baja el bit de "Ready" automáticamente.

    # 3. FILTRADO (Lógica de Negocio)
    li $at, 65             # Cargar código ASCII de 'A'
    blt $k1, $at, salir_k  # Si el carácter < 'A', lo ignoramos y salimos
    
    li $at, 90             # Cargar código ASCII de 'Z'
    bgt $k1, $at, salir_k  # Si el carácter > 'Z', lo ignoramos y salimos

    # 4. ALMACENAMIENTO EN EL BUFFER CIRCULAR
    la $at, buffer         # Cargamos la dirección base de nuestro arreglo
    lw $k0, indice         # Traemos el valor actual del índice (0-9)
    add $at, $at, $k0      # Calculamos: Dirección = Base + Índice
    sb $k1, 0($at)         # Guardamos la letra filtrada en la memoria

    # 5. ACTUALIZACIÓN DEL ÍNDICE (Aritmética Circular)
    addi $k0, $k0, 1       # Incrementamos el índice
    li $at, 10             # Tamaño máximo (BUFFER_SIZE)
    rem $k0, $k0, $at      # $k0 = $k0 % 10 (Si llega a 10, vuelve a 0)
    sw $k0, indice         # Guardamos el nuevo índice para la próxima interrupción

salir_k:
    # 6. RESTAURACIÓN Y RETORNO
    .set noat
    move $at, $k0          # (En este ejemplo simple, restauramos $at)
    .set at
    
    eret                   # EXCEPTION RETURN: Instrucción crítica que:
                           # 1. Devuelve el procesador al Modo Usuario.
                           # 2. Salta a la dirección guardada en el registro EPC (donde estaba el main).