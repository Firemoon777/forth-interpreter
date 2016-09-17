%define pc r15
%define w  r14

%include 'lib.inc'
%include 'macro.asm'
%include 'dict.asm'

section .data
    program_stub:       dq 0
    xt_interpreter:     dq .interpreter
    .interpreter:       dq interpreter_loop
    
    stackHead: 			dq 0
    undefined:          db 'Word is undefined', 10, 0
    underflow:			db 'Stack underflow exception', 10, 0

section .text
global _start
_start:
	; Инициализация интерпретатора
	mov [stackHead], rsp
	mov pc, xt_interpreter
	jmp     next

; Цикл интерпретатора
interpreter_loop:
	call read_word
	mov rdi, rax
	call find_word
	
	test rax, rax
	jnz execute
	call parse_int
	test rdx, rdx
	jz unknown
	push rax
	jmp interpreter_loop

unknown:
	mov rdi, undefined
	call print_string
	mov pc, xt_interpreter
	jmp     next

execute:
	mov rdi, rax
	call cfa
	mov w, rax
	mov [program_stub], rax
	mov pc, program_stub
	jmp next

next: 
	mov w, pc
	add pc, 8
	mov w, [w]
	jmp [w]
	
exit:
	mov rax, 60
	xor rdi, rdi
	syscall
