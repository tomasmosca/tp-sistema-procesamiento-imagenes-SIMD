

section .text
;global main
global aclarar
global aclararSIMD
;main:

aclarar:
 
    push ebp
    mov ebp, esp
    mov eax, [ebp + 20];valor n
    mov ebx, [ebp + 8]; primera matriz red
    call setupIter
    mov ebx, [ebp + 12] ;segunda matriz green
    call setupIter
    mov ebx, [ebp + 16] ;tercera matriz blue
    call setupIter
    JMP fin

    setupIter:
    push ebp
    mov ebp, esp
    mov ecx, 1
    mov esi, 0
    mov edi, 0
    jmp recorro
    
    recorro:
    cmp ecx, 67000
    JE fin
    mov edx, [ebx+esi*4]
    add edx, eax
    cmp edx, 255
    jg overflow
    ;cmp edx, 0
    ;jl underflow
    jmp normal

    overflow:
    mov edx, 255
    ;mov [ebx+esi*4], edx   ;bug al mover dato
    inc ecx
    inc esi
    JMP recorro

    underflow:
    mov edx, 0
    ;mov [ebx+esi*4], edx
    inc ecx
    inc esi
    JMP recorro

    normal:
    mov [ebx+esi*4], dl
    inc ecx
    inc esi
    JMP recorro


aclararSIMD:

    push ebp
    mov ebp, esp
    mov eax, [ebp + 20];  n
    mov ebx, [ebp + 8];  red
    mov esi, [ebp + 12] ; green
    mov edi, [ebp + 16] ; blue
    jmp setup

    setup:
    mov ecx, 2  ;contador
    movd mm7, eax
    jmp cicloSetup

    cicloSetup:
    paddw mm6, mm7  ;en mm6 esta n (ocupa los 64 bytes)
    cmp ecx, 1
    je recorridoPrincipal
    psllq mm6, 8
    dec ecx
    jmp cicloSetup

    recorridoPrincipal:

    cmp ecx, 67000
    je fin

    movd mm0, [ebx+ecx*4]
    movd mm1, [esi+ecx*4]
    movd mm2, [edi+ecx*4]

    paddw mm0, mm6
    paddw mm1, mm6
    paddw mm2, mm6
    
    movd edx, mm0
    call cambio1
    movd edx, mm1
    call cambio2
    movd edx, mm2
    call cambio3

    inc ecx
    jmp recorridoPrincipal


cambio1:
    cmp edx, 255
    jg noMover
    mov [ebx+ecx*4], edx
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

fin:
    mov esp, ebp
    pop ebp
    ret