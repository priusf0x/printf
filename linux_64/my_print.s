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
extern          printf

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
                push rdi

                push rax 

;////////////// Saving vector registers ///////////////////

                movsd [rel sxmm0], xmm0
                movsd [rel sxmm1], xmm1
                movsd [rel sxmm2], xmm2
                movsd [rel sxmm3], xmm3
                movsd [rel sxmm4], xmm4
                movsd [rel sxmm5], xmm5
                movsd [rel sxmm6], xmm6
                movsd [rel sxmm7], xmm7

;///////////////////// Prologue ///////////////////////////
                push rbp 
                mov rbp, rsp

                jmp print

section .data  


; _________________________________________________________
; |                       print                           |
; | Main printf function                                  |
; | Args: Printf arguments considered to C-declaration    |
; |       rdi: Template string                            |
; | Returns:                                              |
; | Delete:                                               |
; _________________________________________________________

section .text

; rsi - pointer to printf buffer
; r8 - argument no   motya sosal
; r11-r15 - save registers
; r9 - float no  

SysCallWrite    equ 1d
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
                xor r9, r9
                mov qword [rel printf_buffer_len], 0

                call transform_string

;;//////////////// Printing string to stdout /////////////// 

                mov rax, SysCallWrite
                mov rdi, StdOut
                mov rdx, [rel printf_buffer_len]
                mov rsi, printf_buffer

                syscall 
            
;//////////////////////// Epilogue ////////////////////////

                pop r15
                pop r14
                pop r13
                pop r12
                pop r11

                mov rsp, rbp
                
                pop rbp
                pop rax

                pop rdi
                pop rsi ; 2st argument 
                pop rdx ; 3st argument 
                pop rcx ; 4st argument 
                pop r8  ; 5st argument 
                pop r9  ; 6st argument

                mov [rel return_adress],rax
                xor rax, rax

                ;call printf
                mov rax, [rel return_adress]
                push rax

                ;mov rax, rdx

                ret

section .data 
return_adress   dq 0
section .text 

; _________________________________________________________
; |                     update_buffer                     |
; | Updates buffer and prints it if it is neccessary      |
; | Args: rdx - insert length                             |
; | Delete: does it fuck you? (not rdi)                   |
; _________________________________________________________

update_buffer:

                mov rcx, [rel printf_buffer_len]
                add rcx, rdx
                cmp rcx, max_printf_buffer_size

                jae .clean_buffer

                mov rsi, printf_buffer
                add rsi, [rel printf_buffer_len]
                mov rcx, rdx 
                add [rel printf_buffer_len], rdx
                mov rdx, insert_buffer

                mov al, [rel is_string]
                test al, al

                jz .loop
                mov rdx, [rel insert_buffer]
                mov byte [rel is_string], 00h

.loop:

                test rcx, rcx
                jz .leave 
                
                mov al, [rdx] 
                mov [rsi], al 
                
                inc rdx 
                inc rsi 
                
                dec rcx 
                jmp .loop

.clean_buffer:
                
                push rdi
                push rdx

                mov rdx, [rel printf_buffer_len] 
                
                mov rax, SysCallWrite
                mov rdi, StdOut
                mov rsi, printf_buffer

                syscall

                mov al, [rel is_string]
                mov rsi, insert_buffer
                test al, al
                jz .skip_string
                mov rsi, [rel insert_buffer]
                mov byte [rel is_string], 00h

.skip_string:

                mov rax, SysCallWrite
                pop rdx

                syscall 

                pop rdi 
                mov qword [rel printf_buffer_len], 0

.leave:

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

                mov rsi, printf_buffer
                xor rdx, rdx

.loop: ; transfering and editing source string to buffer 
                cmp rdx, max_printf_buffer_size  
                jae .clean_buffer

                mov al, [rdi]   
                cmp al, '%'
                je .handle_percent

                mov [rsi], al
                inc rdi
                inc rdx
                inc rsi
                test al, al
                jnz .loop

                mov [rel printf_buffer_len], rdx
                                                        
                ret                                       

.handle_percent:
    
                inc rdi
                mov [rel printf_buffer_len], rdx
                xor rdx, rdx 
                call handle_insertion 
                mov rdx, [rel printf_buffer_len] 
                mov rsi, printf_buffer
                add rsi, rdx
                jmp .loop
                
.clean_buffer:

                push rdi
                mov rax, SysCallWrite
                mov rdi, StdOut
                lea rsi, [rel printf_buffer]
                syscall
                xor rdx, rdx
                mov qword [rel printf_buffer_len], 0
                lea rsi, [rel printf_buffer]
                pop rdi 

                jmp  .loop


                                                          
; _________________________________________________________
; |                handle_insertion                       |
; | Main printf function                                  |
; | Args: rdi - source string                             |
; |       rsi - printable buffer                          |
; | Returns: rdx - string length                          |
; | Delete: rdi, rsi, rax, rcx                            |
; _________________________________________________________

handle_insertion:

                push update_buffer
                mov rsi, insert_buffer

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
                dq .f      ;'f'
                times 'o'-'g' dq .default
                dq .o      ;'o'
                times 's'-'p' dq .default
                dq .s      ;'s'
                times 'x'-'t' dq .default
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
                mov rax, [24 + rbp + r8*8]
                mov [rsi], al
                inc r8

                inc rsi
                inc rdx 
                ret

;//////////////////////////////////////////////////////////

.d:

                mov rax, [24 + rbp + r8*8]
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
                mov rax, [24 + rbp + r8*8]
                inc r8
                mov rcx, 1

                call print_two_power

                ret

;//////////////////////////////////////////////////////////

.x:

                mov rax, [24 + rbp + r8*8]
                inc r8
                mov rcx, 4

                call print_two_power
                
                ret

;//////////////////////////////////////////////////////////

.o:

                mov rax, [24 + rbp + r8*8]
                inc r8
                mov rcx, 3

                call print_two_power
                
                ret

;//////////////////////////////////////////////////////////

.s:

                mov rax, [24 + rbp + r8*8]
                inc r8

                call insert_string

                ret

;//////////////////////////////////////////////////////////

.f:
                
                call get_current_xmm ; xmm0 = arg
                call print_float

                ret 

;//////////////////////////////////////////////////////////

.percent:
                mov byte [rsi], '%'
                inc rsi
                inc rdx 

                ret

;/////////////////e/////////////////////////////////////////


; _________________________________________________________
; |                  print_float                          |
; | Prints float in buffer                                |
; | Args: xmm0 - float number                             |
; | Returns: add to rdx printed amount                    |
; |          skips rsi buffer                             |
; | Delete:                                               |
; _________________________________________________________

int_float_seperator equ '.'
max_float_digits   equ 9d

print_float:

;/////////////////// Print integer part ///////////////////
                xor rax, rax
                cvttsd2si eax, xmm0

                mov r12, rbx 
                mov r13, rsi
                mov r14, rdx

                mov rbx, 10d
                call convert_decemical
                
                mov rbx, r12
                mov rsi, r13
                mov rdx, r14
                
                mov rcx, max_dec_length
                call print_converted

; ////////////////////// Dot //////////////////////////////

                mov [rsi], int_float_seperator
                inc rsi 
                inc rdx

;                cmp eax, 0
;                mov rcx, max_float_digits
;
;.loop:
                 mulsd xmm0, [rel float_part]
;                cvttsd2si rax, xmm0
;                mov al, [rel print_symbols + rax]
;                mov [rsi], al
;                inc rsi

;                inc rd x
;                dec 
;                jnz .loop

                ret
                
section .data 
max_amount_digits equ 10
float_part        dq 1076101120

; WARNING: can increment r8 value 
; _________________________________________________________
; |                  get_current_xmm                      |
; | Puts float number considered to current r9 val        |
; | Args: r9, r8                                          |
; | Returns: xmm0 - current float                         |
; _________________________________________________________

section .text

xmm_regs_amount equ 8

get_current_xmm:
                
                cmp [r9], xmm_regs_amount
                jae .get_from_stack
                movsd xmm0, [xmm_regs + r9*8]
                inc r9
                jmp .leave

.get_from_stack:
                movsd xmm0, [16 + rbp + r8*8]
                inc r8

.leave:
                ret

section .data 
align 16
xmm_regs:
sxmm0           dq 0
sxmm1           dq 0
sxmm2           dq 0
sxmm3           dq 0
sxmm4           dq 0
sxmm5           dq 0
sxmm6           dq 0
sxmm7           dq 0

; _________________________________________________________
; |                  print_two_power                      |
; | Prints rax in 2-power format                          |
; | Args: eax - number                                    |
; |       rcx - power_of_two                              |
; | Returns: add to rdx printed amount                    |
; |          skips rsi buffer                             |
; | Delete: rax, rcx                                      |
; _________________________________________________________

section .text

print_two_power:

                mov r11, r9
                mov r12, rdx
                mov r13, rbx
                mov r14, rsi
                mov r15, rcx

                call convert_two_power
                
                mov rdx, r12
                mov rbx, r13
                mov rsi, r14
                mov rcx, r15

                mov rcx, max_num_len           
                
                call print_converted

                mov r9, r11

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

                mov rbx, 10
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
; ////////////////////// if arg = 0 /////////////////////// 

                test rdx, rdx 
                jnz .leave
                mov [rel insert_buffer], '0' 
                inc rdx
.leave:
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

                mov [rel insert_buffer], rax 

.loop: 
                mov cl, [rax]
                cmp cl, 0
                jz .leave 

                inc rax
                inc rdx
                jmp .loop
.leave:

                mov byte [rel is_string], 0FFh 

                ret                                       
                     
section     .data

max_printf_buffer_size      equ 4096d
printf_buffer_len           dq 0
printf_buffer               db max_printf_buffer_size dup(0)

max_insert_buffer_size      equ 128d
insert_buffer               db max_insert_buffer_size dup(0)
is_string                   db 0

printsign                   db 0
max_num_len                 equ 64
printnumber                 db max_num_len dup (0)


