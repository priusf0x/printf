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
; r11-r15 - save registers
; r15 - float no  

WriteSysCall    equ 1d
StdOut          equ 1d

print: 

;///////////////// Saving "save" registers ////////////////

                push r11
                push r12
                push r13
                push r14
                push r15

;//////////////////////////////////////////////////////////

                lea rsi, [rel printf_buffer]
                xor r8, r8 

                call transform_string

;//////////////// Printing string to stdout /////////////// 

                mov rax, WriteSysCall
                mov rdi, StdOut
; rdx is ready after transform_string
                mov rsi, printf_buffer

                syscall 
            
;//////////////////////// Epilogue ////////////////////////

                pop r15
                pop r14
                pop r13
                pop r12
                pop r11

                add rsp, 5 * 8

                mov rsp, rbp
                
                pop rbp
                pop rax
                add rsp, 8*5
                push rax

                mov rax, rdx

                ret

; _________________________________________________________
; |                     update_buffer                     |
; | Updates buffer and prints it if it is neccessary      |
; | Args: rdx - insert length                             |
; | Delete: does it fuck you?                             |
; _________________________________________________________

update_buffer:

                cmp rdx, [rel printf_buffer_len]
                ja .clean_buffer

.clean_buffer:

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
                dq .b      ;'b'
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

                mov r11, rbx 
                mov r12, rsi
                mov r13, rdx

                mov rbx, 10d
                call convert_decemical
                
                mov rbx, r11
                mov rsi, r12
                mov rdx, r13

                mov rcx, max_dec_length
                call print_converted

                ret

;//////////////////////////////////////////////////////////

.b:
                mov rax, [16 + rbp + r8*8]
                inc r8
                mov rcx, 1

                call print_two_power

                ret

;//////////////////////////////////////////////////////////

.x:

                mov rax, [16 + rbp + r8*8]
                inc r8
                mov rcx, 4

                call print_two_power
                
                ret

;//////////////////////////////////////////////////////////

.o:

                mov rax, [16 + rbp + r8*8]
                inc r8
                mov rcx, 4

                call print_two_power
                
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
; |                  print_two_power                      |
; | Prints rax in 2-power format                          |
; | Args: eax - number                                    |
; |       rcx - power_of_two                              |
; | Returns: add to rdx printed amount                    |
; |          skips rsi buffer                             |
; | Delete: rax, rcx                                      |
; _________________________________________________________

print_two_power:

                mov r11, r9
                mov r12, rdx
                mov r13, rbx
                mov r14, rsi
                mov r15, rcx

                call convert_two_power
                
                mov r9, r11
                mov rdx, r12
                mov rbx, r13
                mov rsi, r14
                mov rcx, r15

                mov rax, max_num_len           
                dec rcx
                shr rax, rcx
                mov rcx, rax
                
                call print_converted

                ret

; _________________________________________________________
; |                  convert_two_power                    |
; | Separate eax in number-buffer in 2-power format       |
; | Args: eax - number                                    |
; |       rcx - power_of_two                              |
; | Delete: rdx, rcx, rax, rsi, rbx, r9, r10              |
; _________________________________________________________

convert_two_power:

                mov byte [rel printsign], 0
                mov rsi, printnumber

                xor r9, r9 
                inc r9 
                shl r9, rcx
                dec r9

                mov rdx, max_num_len           
                dec rcx
                shr rdx, rcx
                inc rcx
                
.loop:
                
                mov rbx, rax 
                and rbx, r9
                mov [rsi], rbx
                inc rsi

                shr rax, cl 
                dec rdx
                jnz .loop

                ret

; _________________________________________________________
; |                convert_decemical                      |
; | Separate eax in number-buffer in decemical format     |
; | Args: eax - number                                    |
; | Returns: add to rdx printed amount                    |
; |          skips rsi buffer                             |
; | Delete: rdx, rcx, rax, rsi, ebx                       |
; _________________________________________________________

max_dec_length  equ 10d

convert_decemical:

                mov byte [rel printsign], 0
                mov rsi, printnumber

                mov bx, 10
                cmp eax, 0
                jge .skip_sign 
                neg rax
                mov byte [rel printsign], 0FFh
.skip_sign:
                mov rcx, max_dec_length
.loop:
                cdq
                idiv ebx
                mov [rsi], edx
                inc rsi
                dec rcx 
                jnz .loop

                ret

; _________________________________________________________
; |                 print_converted                       |
; | Prints converted number                               |
; | Args: rsi - buffer                                    |
; |       rcx - offset                                    |
; | Returns: add to rdx printed amount                    |
; |          skips rsi buffer                             |
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
                add rcx, printnumber 

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
; |                 insert_string                         |
; | Inserts string in buffer                              |
; | Args: rax - ptr to string                             |
; | Returns: add to rdx printed amount                    |
; |          skips rsi buffer                             |
; | Delete: rcx, rax, rsi                                 |
; _________________________________________________________

section .text

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
max_printf_buffer_size      equ 1024d
printf_buffer_len           dq 0
printf_buffer               db max_printf_buffer_size dup(0)

max_insert_buffer_size      equ 128d
insert_buffer               db max_insert_buffer_size dup(0)

printsign                   db 0
max_num_len                 equ 32
printnumber                 db max_num_len dup (0)


