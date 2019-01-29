%include "asm_io.inc"

section .data
   err1: db "incorrect number of command line arguments",10,0
   err2: db "too many discs",10,0
   err3: db "too few discs",10,0
   base: db "XXXXXXXXXXXXXXXXXXXXXXX",10,10,10,0
   init: db "  initial configuration",10,10,0
   final: db "   final configuration",10,10,0
   a1: db "number of disks ",0

section .bss
   ;; will be used to store the # of disks
   d: resd 1
   ;; is an array of size 9 representing the peg
   peg: resd 9

   ;; auxiliary variables
   d1: resd 1

section .text
   global  asm_main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
swapping: ;; expects two arguments on the stack
          ;; the first is the address of the array
          ;; the second is # of disks

    enter 0,0
    pusha

    mov ebx, dword [ebp+8]  ;; ebx is peg
    mov ecx, dword [ebp+12] ;; ecx # of disks

    ;; we have to keep swapping the first entry till its proper position
    mov edx, ebx
    mov esi, 2
    D1: cmp esi, ecx
      ja D2
      mov eax, dword [edx]
      cmp eax, dword [edx+4]
      ja D2
      ;; so we have to swap
      mov eax, dword [edx]
      mov edi, dword [edx+4]
      mov [edx], edi
      mov [edx+4], eax

      add edx, 4
      inc esi
      jmp D1
    D2:  ;; done swapping
    popa
    leave
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
sorthem: ;; expects two arguments on the stack
         ;; the first is the address of the array
         ;; the second is # of disks

    enter 0,0
    pusha

    mov ebx, dword [ebp+8]  ;; ebx holds the address of the array
    mov ecx, dword [ebp+12] ;; ecx holds the # of disks to be sorted

    ;;;; base case ;;;
    S1: cmp ecx, 1     ;; one disks, nothing to sort
    je sorthem_end

    mov edx, ecx       ;; # of disks
    sub edx, 1         ;; less 1
    push edx           ;; store on stack
    mov edx, ebx       ;; the array
    add edx, 4         ;; skip the first element
    push edx           ;; store on stack
    call sorthem
    add esp, 8

    ;; so the tail is sorted
    ;; let us find out where to put peg[0]
    push ecx           ;; # of disks
    push ebx           ;; peg
    call swapping
    add esp, 8

sorthem_end:
    push dword [d]
    push peg
    call showp
    add esp,8

    popa
    leave
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
showp: ;; expects two arguments on the stack
       ;; the first is the address of the array
       ;; the second is # of disks

    enter 0,0
    pusha

    mov eax,dword  [ebp+12]  ;; number of disks
    sub eax,1
    mov ebx,0
    mov bl,4
    mul bl
    ;; eax is the size of the array with non-zero entries
    mov ebx,peg
    add ebx,eax              ;; ebx address of the last non-zero item

    L1:;; [ebx] is the array element
       ;; compute the number of blanks 11-[ebx]
       mov esi,11
       sub esi,[ebx]
       mov edi,0
       L3: cmp edi,esi
       jae L4
           mov al,' '
           call print_char
           inc edi
           jmp L3
       L4:
       mov esi,[ebx]
       mov edi,0
       L5: cmp edi,esi
       jae L6
           mov al,'o'
           call print_char
           inc edi
           jmp L5
       L6: mov al,'|'
       call print_char
       mov esi,[ebx]
       mov edi,0
       L7: cmp edi,esi
       jae L8
           mov al,'o'
           call print_char
           inc edi
           jmp L7
       L8: call print_nl

       cmp ebx,peg
       je L2
       sub ebx,4
       jmp L1
    L2:
    ;; [ebx] is the array element
    mov eax,base
    call print_string

    call read_char

    showp_end:
    popa
    leave
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
asm_main:
    enter 0,0
    pusha

    mov eax, dword [ebp+8]  ; argc
    cmp eax,2
    jne error_argc

    mov ebx, dword [ebp+12]  ; address of argv[]
    mov ecx, dword [ebx+4]   ; get argv[1] argument -- ptr to string
    mov al, byte [ecx+1]
    cmp al, 0
    jne error_argv1
    mov al, byte [ecx]
    sub al, '0'
    cmp eax, 2
    jl error_argv2

    ;; now we have the correct number of discs 2-9
    mov dword [d], eax

    ;; initial setup of r
    push dword [d] ; # of disks
    push peg
    call rconf   ; creates a random configuration of [d] disks on the peg 'peg'
    add esp, 8

    ;; show initial configuration
    mov eax, init
    call print_string
    push dword [d]
    push peg
    call showp
    add esp,8

    push dword [d]  ; # of disks
    push peg
    call sorthem
    add esp, 8

    ;; show final configuration
    mov eax, final
    call print_string
    push dword [d]
    push peg
    call showp
    add esp,8

    jmp end

error_argc:
    mov eax,err1
    call print_string
    jmp end

error_argv1:
    mov eax,err2
    call print_string
    jmp end

error_argv2:
    mov eax,err3
    call print_string
    jmp end

end:
    popa
    leave
    ret
