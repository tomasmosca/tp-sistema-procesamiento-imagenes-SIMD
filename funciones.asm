section .bss
indice resb 1

section .text
global aclarar
global aclararSIMD
global medianFilter
global medianFilterSIMD
global multiplyBlend
global multiplyBlendSIMD

aclarar:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 20] ;valor n
    mov ebx, [ebp + 8]  ;primera matriz red
    call setupIter
    mov ebx, [ebp + 12] ;segunda matriz green
    call setupIter
    mov ebx, [ebp + 16] ;tercera matriz blue
    call setupIter
    JMP fin

    setupIter:      ;setup para inciar el recorrido
    push ebp
    mov ebp, esp
    mov ecx, 0      ;contador
    mov esi, 0      ;para avanzar en el arreglo
    jmp recorro
    
    recorro:
    cmp ecx, 67000          ;cantidad de iteraciones (para cubrir la imagen)
    JE fin
    mov edx, [ebx+esi*4]    ;pixel de esa posicion hacia edx
    add edx, eax            ;suma n al pixel
    cmp edx, 255            ;si es mayor que 255, hay overflow. Si es menor, entonces se modifica el pixel
    jg overflow
    jmp normal

    overflow:               ;si hay overflow, no cambia el pixel, y continua iterando
    inc ecx
    inc esi
    JMP recorro

    normal:                 ;sin overflow, cambia el pixel, usando dl para que entre la posicion a la que se mueve
    mov [ebx+esi*4], dl
    inc ecx
    inc esi
    JMP recorro

;------------------------------------------------------------------

aclararSIMD:

    push ebp
    mov ebp, esp
    mov eax, [ebp + 20];  n
    mov ebx, [ebp + 8];  red
    mov esi, [ebp + 12] ; green
    mov edi, [ebp + 16] ; blue
    jmp setup

    setup:
    mov ecx, 0              ;contador
    movd mm6, eax           ;movemos n hacia mm6
    jmp recorridoPrincipal  ;aqui se realizar la suma a cada reg mmx

    recorridoPrincipal:

    cmp ecx, 67000          ;cantidad de iteraciones
    je fin

    movd mm0, [ebx+ecx*4]   ;pixel en esa posicion hacia el reg mmx
    movd mm1, [esi+ecx*4]
    movd mm2, [edi+ecx*4]

    paddw mm0, mm6          ;se añade n que es el valor que es encuentra en mm6 a cada reg mmx
    paddw mm1, mm6
    paddw mm2, mm6
    
    movd edx, mm0           ;se mueve el resultado hacia los regs de proposito general
    jmp cambio1            ;para cada registro, se verifica que no haya overflow

cambio1:                    ;si hay overflow, no cambia.
    cmp edx, 255
    jg cambio2
    mov [ebx+ecx*4], edx    ;si no hay oveflow, movemos el resultado hacia esa posicion del arreglo
    jmp cambio2
    ret
cambio2:
    movd edx, mm1
    cmp edx, 255
    jg cambio3
    mov [esi+ecx*4], edx
    jmp cambio3
    ret
cambio3:
    movd edx, mm2
    cmp edx, 255
    jg noMover
    mov [edi+ecx*4], edx
    jmp noMover
    ret
noMover:
    inc ecx                 ;incremento contador
    jmp recorridoPrincipal  
    ret

;----------------------------------------------

medianFilter:
    push ebp
    mov ebp, esp
    mov ebx, [ebp+20];window
    mov eax, [ebp+8];red1
    call setupMedian
    mov eax, [ebp+12];green1
    call setupMedian
    mov eax, [ebp+16];blue1
    call setupMedian
    JMP fin

    setupMedian:
    push ebp
    mov ebp, esp
    mov ecx, 2;contador
    mov esi, 2;empiezo en el tercer elemento para no tomar los bordes
    mov edi, 1
    JMP median

    median:
    cmp ecx, 66999 ; penultimo elemento para no tomar el borde
    JE fin
    push ecx
    add ecx, ebx
    CMP ecx, 67000 ;me aseguro de que no se pase del tamaño de la imagen
    JG fin
    pop ecx
    mov [indice], esi
    inc esi
    mov edx, [eax+esi*4]
    inc esi
    JMP sumaMedian

    sumaMedian:
    cmp edi, ebx
    JE promedio
    push ebx
    mov ebx, [eax+esi*4]
    add edx, ebx
    inc edi
    inc esi
    xor ebx, ebx
    pop ebx
    JMP sumaMedian

    promedio:
    push eax ;guardo vector
    xor eax, eax
    mov eax, edx
    xor edx, edx
    idiv ebx ;promedio(eax = suma de pixeles adyacentes/window)
    xor edi, edi
    mov dl, al;resultado final en edx
    xor eax, eax
    pop eax 
    mov esi, [indice] ;recupero el vector
    cmp edx, 255
    JG validarOverflow
    mov byte[eax+esi*4], dl
    inc ecx
    inc esi
    JMP median
    
    validarOverflow:
    inc ecx
    inc esi
    JMP median

;----------------------------------------------

medianFilterSIMD:
    push ebp
    mov ebp, esp
    mov ebx, [ebp+20];window
    mov eax, [ebp+8];red1
    call setupMedian1
    mov eax, [ebp+12];green1
    call setupMedian1
    mov eax, [ebp+16];blue1
    call setupMedian1
    JMP fin

    setupMedian1:
    push ebp
    mov ebp, esp
    mov ecx, 2
    mov esi, 2
    mov edi, 1
    JMP median1
    
    median1:
    CMP ecx, 66999
    JE fin    
    push ecx
    add ecx, ebx
    CMP ecx, 67000 ;me aseguro de que no se pase del tamaño de la imagen
    JG fin
    pop ecx
    mov [indice], esi ;guardo el indice actual 
    inc esi
    mov dl, [eax+esi*4] ;muevo byte a dl
    movd mm0, edx ;muevo el valor al registro mm0
    inc esi
    JMP sumaProm
    
    sumaProm:
    CMP edi, ebx
    JE promedioMMX
    mov dl, [eax+esi*4]
    movd mm1, edx 
    paddw mm0, mm1 ;sumo el valor que esta en mm0 con el valor siguiente que esta en mm1
    inc edi 
    inc esi
    JMP sumaProm

    promedioMMX:
    push eax
    xor eax, eax
    xor edx, edx
    movd eax, mm0
    idiv ebx
    xor edi, edi
    mov dl, al
    xor eax, eax
    pop eax
    cmp edx, 255
    JG validarOverflowSIMD
    mov esi, [indice] ;recupero el indice actual
    mov byte[eax+esi*4], dl ;muevo el resultado al pixel
    inc ecx
    inc esi
    JMP median1

    validarOverflowSIMD:
    inc ecx
    inc esi
    JMP median1

;----------------------------------------------

multiplyBlend:
    push ebp
    mov ebp, esp
    ;limpio los registros
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    ;parametros
    mov eax, [ebp+12]; param green1
    mov ebx, [ebp+24]; param green2
    call setupMul
    mov eax, [ebp+8]; param red1
    mov ebx, [ebp+20]; param red2
    call setupMul
    mov eax, [ebp+16]; param blue1
    mov ebx, [ebp+28]; param blue2
    call setupMul
    JMP fin

setupMul:
    push ebp
    mov ebp, esp
    xor esi, esi
    JMP iteracionROWS

iteracionROWS:
    mov ecx, [eax+esi*4]
    mov edx, [ebx+esi*4]
    xor edi, edi
    jmp multiplyCOLS

multiplyCOLS:
    cmp edi, 512                ;columnas
    Jg finIteracion

    push eax                    ;guardamos valor de eax y ebx en pila
    push ebx
    xor eax, eax                ;los limpiamos
    xor ebx, ebx

    mov al, [ecx+edi]               ; byte de array
    mov bl, [edx+edi]               ; byte de array2

    push edx                        ; guardo edx en la pila porque se usara para guardar el remainder de la division
    push ecx                        ; para contener divisor
    xor ecx, ecx
    xor edx, edx
    mov ecx, 255                    ; divisor
                                    ; formula: (top color * bottom color) / 255
    imul ax, bx                     ; multiplico (ax = ax * bx)
    idiv ecx             ; divido por 255 

    pop ecx
    mov [ecx+edi], al           ; muevo la parte baja que tendra el resultado
    pop edx                     ; dasapilo los registros
    pop ebx  
    pop eax
    inc edi
    JMP multiplyCOLS
    
finIteracion:
    inc esi
    cmp esi, 512            ;filas
    jge fin
    jmp iteracionROWS

;--------------------------------------------------------------

multiplyBlendSIMD:
    push ebp
    mov ebp, esp
    ;muevo parametros a registros
    mov eax, [ebp+8];red1
    mov ebx, [ebp+20];red2
    call setupMul1
    mov eax, [ebp+12];green1
    mov ebx, [ebp+24];green2
    call setupMul1
    mov eax, [ebp+16];blue1
    mov ebx, [ebp+28];blue2
    call setupMul1
    JMP fin

    setupMul1: 
    ;setup inicial para recorrido
    push ebp
    mov ebp, esp
    mov ecx, 0      ;contador
    mov esi, 0      ;multiplicador
    JMP cicloMul

    cicloMul:

    cmp ecx, 67000
    je fin
    xor edx, edx            ;limpio edx
    mov dl, [eax+ecx*4]     ;muevo byte a dl
    push eax                ;guardo eax para usarlo
    xor eax, eax            ;limpio eax
    mov al, [ebx+ecx*4]     ;muevo byte a al
    movd mm0, edx           ;muevo los valores a los registros mmx
    movd mm1, eax
    pop eax                 ;eax queda como antes

    pmullw mm0, mm1         ;multiplico los registros mmx y resultado queda en mm0
    push eax                ;guardo eax
    xor eax, eax            ;limpio registros
    xor edx, edx
    movd eax, mm0           ;movemos resultado a eax
    mov esi, 255            ;255 a esi para dividir
    div esi                 ;dividimos esi y queda el resultado en eax
    cmp eax, 255            ;verifico overflow
    jg noCambia             ;si no hay, no cambiamos pixel
    xor edx, edx            
    mov dl, al              ;movemos resultado a dl
    pop eax
    mov [eax+ecx*4], dl     ;cambiamos pixel
    inc ecx
    jmp cicloMul

    noCambia:           ; hay overflow, continua recorrido
    inc ecx
    pop eax
    jmp cicloMul

fin:
    mov esp, ebp
    pop ebp
    emms            ; para liberar mmx
    ret

