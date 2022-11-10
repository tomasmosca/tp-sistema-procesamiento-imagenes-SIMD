

section .text
;global main
global aclarar
;main:

aclarar:
 
    push ebp
    mov ebp, esp
    mov eax, 50;valor n
    mov ebx, [ebp +8]; primera matriz red
    call setupIter
    mov ebx, [ebp +12] ;segunda matriz green
    call setupIter
    mov ebx, [ebp +16] ;tercera matriz blue
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
    mov [ebx+esi*4], edx
    inc ecx
    inc esi
    JMP recorro
    
    fin:
    mov esp, ebp
    pop ebp
    ret
    