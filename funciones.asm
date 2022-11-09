

section .text
;global main
global aclarar
;main:

aclarar:
 
    push ebp
    mov ebp, esp
    mov eax, dword[ebp +20];valor n
    mov ebx, dword[ebp +8]; primera matriz red
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
    jmp reco
    
    reco:
    cmp ecx, 67000
    JE fin
    add [ebx+esi*4], eax
    inc ecx
    inc esi
    JMP reco
    
    fin:
    mov esp, ebp
    pop ebp
    ret
    