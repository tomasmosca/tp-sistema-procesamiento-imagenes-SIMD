

section .text
global aclarar
global aclararSIMD
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
    mov ecx, 1              ;contador
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
    call cambio1            ;para cada registro, se verifica que no haya overflow
    movd edx, mm1
    call cambio2
    movd edx, mm2
    call cambio3

    inc ecx                 ;incremento contador
    jmp recorridoPrincipal  


cambio1:                    ;si hay overflow, no cambia.
    cmp edx, 255
    jg noMover
    mov [ebx+ecx*4], edx    ;si no hay oveflow, movemos el resultado hacia esa posicion del arreglo
    ret
cambio2:
    cmp edx, 255
    jg noMover
    mov [esi+ecx*4], edx
    ret
cambio3:
    cmp edx, 255
    jg noMover
    mov [edi+ecx*4], edx
    ret

noMover:
    ret

;----------------------------------------------

multiplyBlend:
    push ebp
    ;limpio los registros
    mov ebp, esp
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    mov eax, [ebp+8];red1
    mov ebx, [ebp+20];red2
    call setupMul
    mov eax, [ebp+12];green1
    mov ebx, [ebp+24];green2
    call setupMul
    mov eax, [ebp+16];blue1
    mov ebx, [ebp+28];blue2
    call setupMul
    JMP fin

setupMul:
    push ebp
    mov ebp, esp
    mov ecx, 0  ; contador
    mov esi, 0  ; multiplicador
    mov edi, 0
    JMP multiply
    
multiply:
    cmp ecx, 67000
    JE fin
    mov dl, byte[eax+esi*4] ; byte de red1
    push eax  ; Temp
    push ecx  ; para contener el 255 a dividir
    xor eax, eax  ; limpiamos eax
    xor ecx, ecx
    mov al, byte[ebx+esi*4]  ; byte de red2
    imul eax, edx  ; multiplico (eax = red1 * red2)
    push edx ; push edx a la pila porque va a haber remainder de division
    xor edx, edx ; limpio edx
    ;division anda mal
    ;mov ecx, 255 ; muevo 255
    ;idiv ecx ; division (eax = red1 * red2 / 255)
    cmp eax, 255
    jge cambioMul
    xor edx, edx
    pop edx ; edx queda como antes
    mov dl, al ; resultado final en edx
    pop ecx ; ecx como antes
    xor eax, eax
    pop eax ; eax como antes
    mov byte[eax+esi*4], dl
    inc ecx
    inc esi
    JMP multiply


cambioMul:
    pop edx
    pop ecx
    inc ecx
    inc esi
    pop eax
    JMP multiply

;--------------------------------------------------------------

multiplyBlendSIMD:
    push ebp
    mov ebp, esp
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
    push ebp
    mov ebp, esp
    mov ecx, 0
    mov esi, 0
    xor edi, edi
    JMP cicloMul

    cicloMul:

    cmp ecx, 67000
    je fin
    xor edx, edx
    mov dl, [eax+ecx*4]
    push eax
    xor eax, eax
    mov al, [ebx+ecx*4]
    movd mm0, edx
    movd mm1, eax
    pop eax

    pmullw mm0, mm1
    push eax
    xor eax, eax
    xor edx, edx
    movd eax, mm0
    push eax
    xor eax, eax
    mov al, [esp]
    add esp, 4
    mov esi, 250
    ;div esi
    cmp al, 250
    jg noCambia
    ;cmp edx, 0
    ;jl noCambia
    xor edx, edx
    mov dl, al
    pop eax
    mov [eax+ecx*4], dl
    inc ecx
    jmp cicloMul

    noCambia:
    inc ecx
    pop eax
    jmp cicloMul

fin:
    mov esp, ebp
    pop ebp
    emms            ; para liberar mmx
    ret

