.data
    msg_verde:    .asciiz "\nSemáforo en verde, esperando pulsador\n"
    msg_pulsador: .asciiz "Pulsador activado: en 20 segundos, el semáforo cambiará a amarillo\n"
    msg_amarillo: .asciiz "Semáforo en amarillo, en 10 segundos, semáforo en rojo\n"
    msg_rojo:     .asciiz "Semáforo en rojo, en 30 segundos, semáforo en verde\n"

.text
.globl main

main:
estado_verde:
    # 1. Imprimir estado verde
    li $v0, 4
    la $a0, msg_verde
    syscall

    # 2. Configurar dirección base de MMIO del teclado (0xffff0000)
    lui $t0, 0xffff      

esperar_tecla:
    # Leer el Receiver Control Register (Registro de control)
    lw $t1, 0($t0)       
    
    # Extraer el bit 0 (Ready bit) para saber si hay una tecla disponible
    andi $t1, $t1, 1     
    
    # Si el bit es 0, no hay tecla, seguir esperando (bucle de polling)
    beq $t1, $zero, esperar_tecla 

    # Si hay tecla, leer el Receiver Data Register (Registro de datos)
    lw $t2, 4($t0)       
    
    # Verificar si la tecla presionada es 's' (ASCII 115) o 'S' (ASCII 83)
    li $t3, 115          
    beq $t2, $t3, secuencia_semaforo 
    li $t3, 83           
    beq $t2, $t3, secuencia_semaforo
    
    # Si es cualquier otra tecla, se ignora y sigue esperando
    j esperar_tecla      

secuencia_semaforo:
    # 3. Imprimir mensaje de pulsador activado
    li $v0, 4
    la $a0, msg_pulsador
    syscall

    # Iniciar temporizador de 20 segundos (20000 milisegundos)
    li $v0, 32
    li $a0, 20000
    syscall

estado_amarillo:
    # 4. Imprimir estado amarillo
    li $v0, 4
    la $a0, msg_amarillo
    syscall

    # Iniciar temporizador de 10 segundos (10000 milisegundos)
    li $v0, 32
    li $a0, 10000
    syscall

estado_rojo:
    # 5. Imprimir estado rojo
    li $v0, 4
    la $a0, msg_rojo
    syscall

    # Iniciar temporizador de 30 segundos (30000 milisegundos)
    li $v0, 32
    li $a0, 30000
    syscall

    # 6. Reiniciar el ciclo volviendo al estado verde
    j estado_verde