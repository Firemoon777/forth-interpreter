%define pc r15
%define w  r14
%define rstack r13
%define here rbx

%include 'lib.inc'
%include 'macro.asm'
%include 'dict.asm'

section .data
    program_stub:       dq 0
    xt_interpreter:     dq .interpreter
    .interpreter:       dq interpreter_loop
    
    xt_compiler:     	dq .compiler
    .compiler:       	dq compiler_loop
    
    undefined:          db 'Word is undefined', 10, 0
    underflow:			db 'Stack underflow exception', 10, 0
    interpreter_msg		db 'Switch to interpreter mode', 10, 0
    compiler_msg		db 'Switch to compiler mode', 10, 0

section .bss
	retstack: 			resq 65536 
	userstack: 			resq 65536
	dictionary			resq 65536
	stackHead:  		resq 1
	ustackHead:  		resq 1
	state:      		resq 1
	
section .text
global _start
_start:
	; Инициализация интерпретатора
	mov [stackHead], rsp
	mov rstack, retstack + 65536*word_size
	mov qword[ustackHead], userstack + 65536*word_size
	mov here, dictionary
	mov pc, xt_interpreter
	jmp     next

; Цикл интерпретатора
interpreter_loop:
	mov al, byte[state]
	test al, al
	jnz compiler_loop
	
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

; Цикл компилятора
compiler_loop:
	;mov rdi, compiler_msg
	;call print_string
	mov al, byte[state]
	test al, al
	jz interpreter_loop
	
	call read_word
	mov rdi, rax
	call find_word
	
	test rax, rax
	jz .check_number
	mov rdi, rax
	call cfa
	mov dil, byte[rax-1]
	test dil, dil
	jz .compile ; Прыжок, если нужна компиляция
	mov w, rax
	mov [program_stub], rax
	mov pc, program_stub
	jmp next
	.compile:
		mov [here], rax
		add here, word_size
	jmp compiler_loop
	.check_number:
		call parse_int
		test rdx, rdx
		jz unknown
		mov qword[here], xt_lit
		add here, word_size
		mov [here], rax
		add here, word_size
	jmp compiler_loop

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
	
close:
	mov rax, 60
	xor rdi, rdi
	syscall

