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

default rel
section .text

%macro push_xmm 1
                sub rsp, 8
                movsd [rsp], %1
%endmacro

my_pr1ntf:

                mov [rax_save], rax

                pop rax
;///////////////// Pushing arguments register /////////////

                push r9  ; 6st argument
                push r8  ; 5st argument 
                push rcx ; 4st argument 
                push rdx ; 3st argument 
                push rsi ; 2st argument 

                mov r8, rsp 
                add r8, R_AMOUNT * 8

                mov [r_adress], rsp
                mov [r_amount], 0

;////////////// Saving vector registers ///////////////////
                
                mov byte [is_float_used], 0h
                mov qword [float_amount], 0
                mov rcx, [rax_save]
                test cl, cl 
                jz .skip_float_save
                push_xmm xmm7
                push_xmm xmm6
                push_xmm xmm5
                push_xmm xmm4
                push_xmm xmm3
                push_xmm xmm2
                push_xmm xmm1
                push_xmm xmm0
                mov [float_adress], rsp
                mov byte [is_float_used], 0FFh
.skip_float_save:

                push rax 

;///////////////////// Prologue ///////////////////////////

                push rbp 
                mov rbp, rsp

;///////////////// Saving "save" registers ////////////////

                push r10
                push r11
                push r12
                push r13
                push r14
                push r15
                push rbx

                jmp print

section .data  
rax_save        dq 0
is_float_used   db 0


; _________________________________________________________
; |                       print                           |
; | Main printf function                                  |
; | Args: Printf arguments considered to C-declaration    |
; |       rdi: Template string                            |
; | Returns:                                              |
; | Delete:                                               |
; _________________________________________________________

section .text

; rdi - pointer to const char string 
; r8 - adress to stack args
; r12-r15 - save registers

SYS_CALL_WRITE  equ 1d
STD_OUT         equ 1d

print: 

;//////////////////////////////////////////////////////////

                lea rsi, [printf_buffer]
                mov qword [float_amount], 0
                mov qword [printf_buffer_len], 0

                call transform_string

;;//////////////// Printing string to stdout /////////////// 

                mov rax, SYS_CALL_WRITE
                mov rdi, STD_OUT
                mov rdx, [printf_buffer_len]
                lea rsi, [printf_buffer]

                syscall 

;//////////////////////// Epilogue ////////////////////////

                pop rbx
                pop r15
                pop r14
                pop r13
                pop r12
                pop r11
                pop r10

                mov rsp, rbp

                pop rbp
                pop rax

                mov cl, [is_float_used]
                test cl, cl
                jz .skip_float_del
                add rsp, XMM_REGS_AMOUNT * 8
.skip_float_del:

                add rsp, R_AMOUNT * 8

                push rax

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

                mov rcx, [printf_buffer_len]
                add rcx, rdx
                cmp rcx, MAX_PRINTF_BUFFER_SIZE

                jae .clean_buffer

                lea rsi, [printf_buffer]
                add rsi, [printf_buffer_len]
                mov rcx, rdx 
                add [printf_buffer_len], rdx
                lea rdx, [insert_buffer]

                mov al, [is_string]
                test al, al

                jz .loop
                mov rdx, [insert_buffer]
                mov byte [is_string], 00h

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

                mov rdx, [printf_buffer_len] 

                mov rax, SYS_CALL_WRITE
                mov rdi, STD_OUT
                lea rsi, [printf_buffer]

                syscall

                mov al, [is_string]
                lea rsi, [insert_buffer]
                test al, al
                jz .skip_string
                mov rsi, [insert_buffer]
                mov byte [is_string], 00h

.skip_string:

                mov rax, SYS_CALL_WRITE
                pop rdx

                syscall 

                pop rdi 
                mov qword [printf_buffer_len], 0

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

                lea rsi, [printf_buffer]
                xor rdx, rdx

.loop: ; transfering and editing source string to buffer 
                cmp rdx, MAX_PRINTF_BUFFER_SIZE
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

                mov [printf_buffer_len], rdx

                ret                                       

.handle_percent:

                inc rdi
                mov [printf_buffer_len], rdx
                xor rdx, rdx 
                call handle_insertion 
                mov rdx, [printf_buffer_len] 
                lea rsi, [printf_buffer]
                add rsi, rdx
                jmp .loop

.clean_buffer:

                push rdi
                mov rax, SYS_CALL_WRITE
                mov rdi, STD_OUT
                lea rsi, [printf_buffer]
                syscall
                xor rdx, rdx
                mov qword [printf_buffer_len], 0
                lea rsi, [printf_buffer]
                pop rdi 

                jmp  .loop



; _________________________________________________________
; |                handle_insertion                       |
; | Main printf function                                  |
; | Args: rdi - source string                             |
; |       rsi - printable buffer                          |
; | Returns: rdx - string length                          |
; | Delete: rsi, rax, rcx, r9                             |
; _________________________________________________________

handle_insertion:

                lea rcx, [update_buffer]
                push rcx
                lea rsi, [insert_buffer]

                xor rax, rax 

                mov al, [rdi]   
                inc rdi

                sub al, '%'     ; formatting character for jump_table
                cmp al, 'x'     ; other default cases  
                ja .default     ; Lower bound is checked by this condition (x - '%' > 128)

                lea rcx, [.jump]
                lea r9, [.jump_table]
                add rcx, [r9 + 8*rax]
.jump:
                jmp rcx

section .rdata 
.jump_table:
                dq .percent                 - .jump;'%'
                times 'a'-'%'-1 dq .default - .jump
                dq .default                 - .jump;'a'
                dq .b                       - .jump;'b'
                dq .c                       - .jump;'c'
                dq .d                       - .jump;'d'
                dq .default                 - .jump;'e'
                dq .f                       - .jump;'f'
                times 'o'-'g' dq .default   - .jump
                dq .o                       - .jump;'o
                times 's'-'p' dq .default   - .jump
                dq .s                       - .jump;'s'
                times 'x'-'t' dq .default   - .jump
                dq .x                       - .jump;'x'

section .text

;//////////////////////////////////////////////////////////

.default:
                inc rdi
                ret

;//////////////////////////////////////////////////////////

.c:
                call get_current_r
                mov [rsi], al

                inc rsi
                inc rdx 
                ret

;//////////////////////////////////////////////////////////
.d:

                call get_current_r

                mov r14, rbx 
                mov r12, rsi
                mov r13, rdx

                call convert_decimal

                mov rbx, r14
                mov rsi, r12
                mov rdx, r13                                                              

                mov rcx, MAX_DEC_LENGTH
                call print_converted

                ret

;//////////////////////////////////////////////////////////

.b:
                call get_current_r

                mov rcx, 1
                call print_two_power

                ret

;//////////////////////////////////////////////////////////

.x:
                call get_current_r

                mov rcx, 4
                call print_two_power

                ret

;//////////////////////////////////////////////////////////

.o:
                call get_current_r

                mov rcx, 3
                call print_two_power

                ret

;//////////////////////////////////////////////////////////

.s:
                call get_current_r

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

;//////////////////////////////////////////////////////////


; _________________________________________________________
; |                  print_float                          |
; | Prints float in buffer                                |
; | Args: xmm0 - float number                             |
; | Returns: add to rdx printed amount                    |
; |          skips rsi buffer                             |
; | Delete:                                               |
; _________________________________________________________

INT_FLOAT_SEPARATOR equ '.'
MAX_FLOAT_DIGITS    equ 9d

print_float:

                pxor xmm1, xmm1
                ucomisd xmm0, xmm1
                ja .skip_sign
                mov [rsi], '-'
                inc rsi
                inc rdx
                andpd xmm0, [ABS_MASK_DOUBLE]
.skip_sign:

;/////////////////// Print integer part ///////////////////
                xor rax, rax
                cvttsd2si eax, xmm0
                cvtsi2sd xmm1, eax
                subsd xmm0, xmm1

                mov r13, rsi
                mov r14, rdx

                call convert_decimal

                mov rsi, r13
                mov rdx, r14

                mov rcx, MAX_DEC_LENGTH
                call print_converted

; ////////////////////// Dot //////////////////////////////

                mov [rsi], INT_FLOAT_SEPARATOR
                inc rsi 
                inc rdx

; //////////////////// Float_part /////////////////////////

                mov rcx, MAX_FLOAT_DIGITS
                movsd xmm2, [FLOAT_TEN] 

.loop:

                mulsd xmm0, xmm2
                cvttsd2si eax, xmm0
                cvtsi2sd xmm1, eax
                subsd xmm0, xmm1
                add al, '0'
                mov [rsi], al 
                inc rsi 
                inc rdx
                dec rcx
                test rcx, rcx
                jnz .loop

                ret

section .rdata 
align 16
ABS_MASK_DOUBLE dq 0x7FFFFFFFFFFFFFFF, 0
FLOAT_TEN       dq 10.0, 0

; _________________________________________________________
; |                  get_current_r                        |
; | Get current integer register                          |
; | Args: r9, r8                                          |
; | Returns: rax - current int                            |
; | Delete: rcx                                           |
; _________________________________________________________

section .text

R_AMOUNT        equ 5d

get_current_r:
                
                mov r9, [r_amount]
                cmp r9, R_AMOUNT
                je .get_from_stack
                mov rcx, [r_adress]
                mov rax, [rcx]
                add rcx, 8 
                mov [r_adress], rcx
                inc r9 
                mov [r_amount], r9

                ret

.get_from_stack:
                mov rax, [r8]
                add r8, 8

                ret

section .data 
r_adress        dq 0
r_amount        dq 0
     
; _________________________________________________________
; |                  get_current_xmm                      |
; | Puts float number considered to current r9 val        |
; | Args: r9, r8                                          |
; | Returns: xmm0 - current float                         |
; | Delete: rcx                                           |
; _________________________________________________________

section .text

XMM_REGS_AMOUNT equ 8

get_current_xmm:
                
                mov r9, [float_amount]
                cmp r9, XMM_REGS_AMOUNT
                je .get_from_stack
                mov rcx, [float_adress]
                movsd xmm0, [rcx]
                add rcx, 8
                mov [float_adress], rcx
                inc r9
                mov [float_amount], r9
                ret 

.get_from_stack:
                movsd xmm0, [r8]
                add r8, 8

                ret


section .data 
float_adress    dq 0
float_amount    dq 0

; _________________________________________________________
; |                  print_two_power                      |
; | Prints rax in 2-power format                          |
; | Args: rax - number                                    |
; |       rcx - power_of_two                              |
; | Returns: add to rdx printed amount                    |
; |          skips rsi buffer                             |
; | Delete: rax, rcx                                      |
; _________________________________________________________

section .text

print_two_power:

                mov r12, rdx
                mov r14, rsi
                mov r15, rcx

                call convert_two_power

                mov rdx, r12
                mov rsi, r14
                mov rcx, r15

                mov rcx, MAX_NUM_LEN          

                call print_converted

                ret

; _________________________________________________________
; |                  convert_two_power                    |
; | Separate eax in number-buffer in 2-power format       |
; | Args: rax - number                                    |
; |       rcx - power_of_two                              |
; | Delete: rdx, rcx, rax, rsi, rbx, r9, r10              |
; _________________________________________________________

convert_two_power:

                mov byte [print_sign], 0
                lea rsi, [print_number]

                xor r9, r9 
                inc r9 
                shl r9, rcx
                dec r9

                mov rdx, MAX_NUM_LEN           

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
; |                convert_decimal                        |
; | Separate eax in number-buffer in decimal format       |
; | Args: eax - number                                    |
; | Returns: add to rdx printed amount                    |
; |          skips rsi buffer                             |
; | Delete: rdx, rcx, rax, rsi, ebx                       |
; _________________________________________________________
MAX_DEC_LENGTH  equ 10d

convert_decimal:

                mov byte [print_sign], 0
                lea rsi, [print_number]

                mov rbx, 10
                cmp eax, 0
                jge .skip_sign 
                neg rax
                mov byte [print_sign], 0FFh
.skip_sign:
                mov rcx, MAX_DEC_LENGTH
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
; | Delete: rsi, rax, rcx, r9, rbx                        |
; _________________________________________________________

print_converted:

                xor rax, rax

                mov al, [print_sign]
                cmp al, 0
                je .skip_sign
                mov [rsi], '-'
                inc rsi
                inc rdx

.skip_sign: 

                lea r9, [print_number]
                add rcx, r9 
                xor r9b, r9b

.loop:
                dec rcx
                mov al, [rcx]
                cmp al, 0
                je .skip_flag_set
                mov r9b, 0FFh
.skip_flag_set:
                cmp r9b, 0
                je .skip_num
                lea rbx, [PRINT_SYMBOLS]
                mov r9b, [rbx + rax]
                mov [rsi], r9b
                inc rsi
                inc rdx
.skip_num:
                lea rbx, [print_number]
                cmp rcx, rbx
                jne .loop
; ////////////////////// if arg = 0 /////////////////////// 

                cmp r9b, 0  
                jne .leave
                mov [rsi], '0' 
                inc rdx
                inc rsi
.leave:
                ret

section .rdata 
PRINT_SYMBOLS db "0123456789abcdef"

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

                mov [insert_buffer], rax 

.loop: 
                mov cl, [rax]
                cmp cl, 0
                jz .leave 

                inc rax
                inc rdx
                jmp .loop
.leave:

                mov byte [is_string], 0FFh 

                ret                                       

section     .data

MAX_PRINTF_BUFFER_SIZE      equ 1000h
printf_buffer_len           dq 0
printf_buffer               db MAX_PRINTF_BUFFER_SIZE dup(0)

MAX_INSERT_BUFFER_SIZE      equ 128d
insert_buffer               db MAX_INSERT_BUFFER_SIZE dup(0)
is_string                   db 0

print_sign                  db 0
MAX_NUM_LEN                 equ 64
print_number                db MAX_NUM_LEN dup (0)


