; =========================================================
; |                 Printf implementation                 |
; | Filename:................................. my_print.s |
; | Architect:.....................................x86_16 |
; | Assembler:...................................... nasm |
; | Made for:.................................. Linux x86 |
; | Author:..................................... pr1usf0x |
; =========================================================

; _________________________________________________________
; |                     Function name                     |
; _________________________________________________________

global          my_pr1ntf

; _________________________________________________________
; |                       my_pr1ntf                       |
; | Trampoline for printf function.                       |
; | Args: Printf arguments considered to Fast-declaration |
; | Returns:                                              |
; | Delete:                                               |
; _________________________________________________________

section .text

my_pr1ntf:

                pop rax
;///////////////// Pushing arguments register /////////////

                push r9  ; 6st argument
                push r8  ; 5st argument 
                push rcx ; 4st argument 
                push rdx ; 3st argument 
                push rsi ; 2st argument 

                push rax 

;///////////////////// Prologue ///////////////////////////
                push rbp 
                mov rbp, rsp

                jmp print

; _________________________________________________________
; |                       print                           |
; | Main printf function                                  |
; | Args: Printf arguments considered to C-declaration    |
; |       rdi: Template string                            |
; | Returns:                                              |
; | Delete:                                               |
; _________________________________________________________

; rsi - pointer to printf buffer
; r8 - argument no

WriteSysCall    equ 1d
StdOut          equ 1d

print: 
                lea rsi, [rel buffer]
                xor r8, r8 

                call transform_string

;//////////////// Printing string to stdout /////////////// 

                mov rax, WriteSysCall
                mov rdi, StdOut
; rdx is ready after transform_string
                mov rsi, buffer

                syscall 
            
;//////////////////////// Epilogue ////////////////////////

                add rsp, 5 * 8

                mov rsp, rbp
                
                pop rbp
                pop rax
                add rsp, 8*5
                push rax

                mov rax, rdx

                ret

; _________________________________________________________
; |                 transform_string                      |
; | Transgorming and editing string                       |
; | Args: rdi - source string                             |
; |       rsi - printable buffer                          |
; | Returns: rdx - string length                          |
; | Delete: rdi, rsi, rax                                 |
; _________________________________________________________
                                                          
transform_string:

                xor rdx, rdx 

.loop: ; transfering and editing source string to buffer 
                mov al, [rdi]   

                inc rdx
                inc rsi
                inc rdi

                cmp al, '%'
                jne .skip_call
                call handle_insertion 
                jmp .skip_insertion
.skip_call:
                mov [rsi], al
.skip_insertion:
                
                cmp al, 0
                jne .loop
                                                        
                ret                                       
                                                          
; _________________________________________________________
; |                handle_insertion                       |
; | Main printf function                                  |
; | Args: rdi - source string                             |
; |       rsi - printable buffer                          |
; | Returns: rdx - string length                          |
; | Delete: rdi, rsi, rax, rcx                            |
; _________________________________________________________

handle_insertion:

                xor rax, rax 

                mov al, [rdi]   
                inc rdi
                cmp al, '%'
                je .percent

                sub al, 'a'     ; formatting character for jump_table

                cmp al, 'z'     ; other default cases  
                ja .default

                jmp [.jump_table + 8*rax]

section .rdata 
.jump_table:
                dq .default;'a'
                dq .default;'b'
                dq .c      ;'c'
                dq .d      ;'d'
                dq .default;'e'
                dq .default;'f'
                dq .default;'g'
                dq .default;'h'
                dq .default;'i'
                dq .default;'j'
                dq .default;'k'
                dq .default;'l'
                dq .default;'m'
                dq .default;'n'
                dq .o      ;'o'
                dq .default;'p'
                dq .default;'q'
                dq .default;'r'
                dq .s      ;'s'
                dq .default;'t'
                dq .default;'u'
                dq .default;'v'
                dq .default;'w'
                dq .x;      'x'
                dq .default;'y'
                dq .default;'z'

section .text

;//////////////////////////////////////////////////////////

.default:
                inc rdi
                ret


;//////////////////////////////////////////////////////////

.c:
                mov rax, [16 + rbp + r8]
                mov [rsi], al

                inc rsi
                inc rdx 
                inc r8
                ret

;//////////////////////////////////////////////////////////

.d:

                mov rax, [16 + rbp + r8*8]
                inc r8

                push rbx 
                mov rbx, 10d
                call print_in_system
                pop rbx

                ret

;//////////////////////////////////////////////////////////

.x:

                mov rax, [16 + rbp + r8*8]
                inc r8

                push rbx 
                mov rbx, 16d
                call print_in_system
                pop rbx
                
                ret

;//////////////////////////////////////////////////////////

.o:

                mov rax, [16 + rbp + r8*8]
                inc r8

                push rbx 
                mov rbx, 8d
                call print_in_system
                pop rbx

                ret

;//////////////////////////////////////////////////////////

.s:

                mov rax, [16 + rbp + r8*8]
                inc r8

                call insert_string

                ret


;//////////////////////////////////////////////////////////

.percent:
                mov byte [rsi], '%'
                inc rsi
                inc rdx 
                ret

;//////////////////////////////////////////////////////////

; _________________________________________________________
; |                print_converted                        |
; | Main printf function                                  |
; | Args: eax - number                                    |
; |       ebx - numerical system                          |
; | Returns: rcx - string length                          |
; | Delete: rdx, rcx, rax, rsi                            |
; _________________________________________________________

convert_number:

                mov byte [rel printsign], 0
                mov rsi, printnumber

                cmp eax, 0
                jge .skip_sign 
                neg rax
                mov byte [rel printsign], 0FFh
.skip_sign:
                mov rcx, max_num_len
.loop:
                cdq
                idiv ebx
                mov [rsi], edx
                inc rsi
                dec cx 
                jnz .loop

                ret

; _________________________________________________________
; |                 print_converted                       |
; | Print converted number                                |
; | Args: rsi - buffer                                    |
; | Returns: adds to rdx amount of symbols                |
; | Delete: rsi, rax, rcx, r9                             |
; _________________________________________________________

print_converted:

                xor rax, rax
                mov al, [rel printsign]
                cmp al, 0
                je .skip_sign
                mov [rsi], '-'
                inc rsi
                inc rdx

.skip_sign: 

                xor r9b, r9b
                mov rcx, printnumber + max_num_len

.loop:
                dec rcx
                mov al, [rcx]
                cmp al, 0
                je .skip_flag_set
                mov r9b, 0FFh
.skip_flag_set:
                cmp r9b, 0
                je .skip_num
                mov r9b, [print_symbols + rax]
                mov [rsi], r9b
                inc rsi
                inc rdx
.skip_num:
                cmp rcx, printnumber
                jne .loop

                ret

section     .rdata 
print_symbols db "0123456789abcdef"

; _________________________________________________________
; |                 print_in_system                       |
; | Inserts number in buffer                              |
; | Args: rax - number                                    |
; |       rbx - numerical system                          |
; | Returns: adds to rdx amount of symbols                |
; | Delete: rsi, rax, rcx, r9, rbx                        |
; _________________________________________________________

section .text

print_in_system:

                push rsi 
                push rbx

                mov r9, rdx
                call convert_number
                mov rdx, r9 

                pop rbx
                pop rsi

                call print_converted

                ret

; _________________________________________________________
; |                 insert_string                         |
; | Inserts string in buffer                              |
; | Args: rax - ptr to string                             |
; | Returns: adds to rdx amount of symbols                |
; | Delete: rcx, rax, rsi                                 |
; _________________________________________________________

insert_string:

.loop: 
                mov cl, [rax]   
                mov [rsi], cl

                inc rdx
                inc rsi
                inc rax

                cmp cl, 0
                jne .loop
                                                        
                ret                                       

section     .data
max_buffer_size equ 1024d
buffer      db max_buffer_size dup(0)
printsign   db 0
max_num_len equ 16
printnumber db max_num_len dup (0)


