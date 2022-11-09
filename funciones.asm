

section .text
;global main
global aclarar
;main:

aclarar:
 
    push ebp
    mov ebp, esp
    mov eax, dword[ebp +20];valor n
    mov ebx, dword[ebp +8]; primera matriz red
    mov ecx, 1
    mov esi, 0
    call reco
    mov ebx, [ebp +12] ;segunda matriz green
    mov ecx, 1
    mov esi, 0
    call reco
    mov ebx, [ebp +16] ;tercera matriz blue
    mov ecx, 1
    mov esi, 0
    call reco
    JMP fin
    
    reco:
    cmp ecx, 262144
    JE fin
    add [ebx+esi*4], eax
    inc ecx
    inc esi
    JMP reco
    
    fin:
    mov esp, ebp
    pop ebp
    ret