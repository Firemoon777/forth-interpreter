%define pc r15
%define w  r14
%define rstack r13
%define here rbx

%include 'lib.inc'
%include 'macro.asm'
%include 'dict.asm'

section .data
    program_stub:       dq 0
    ;bootstrap_interpreter_loop: dq xt_bootstrap_interpreter_loop
xt_bootstrap_interpreter_loop:
    dq xt_lit
	dq current_word
	dq xt_dup
	dq xt_wordreader
	dq xt_drop
	dq xt_find
	dq xt_dup
	dq xt_branch0 ; Если слова нет в словаре, то переходим к обработке цифр
	dq 2
; Выполнение команды
	dq xt_cfa_bootstrap 
	dq xt_exec
; Обработка цифр
	dq xt_drop
	dq xt_lit
	dq current_word
	dq xt_parse
	dq xt_branch0
	dq 1
	dq xt_b_loop
; Слово не найдено, цифрой не является
	dq xt_drop
	dq xt_lit
	dq undefined
	dq xt_write
	dq xt_b_loop
	
	
    undefined:          db 'Word is undefined', 10, 0
    underflow:			db 'Stack underflow exception', 10, 0
    interpreter_msg:	db 'Switch to interpreter mode', 10, 0
    compiler_msg:		db 'Switch to compiler mode', 10, 0
	xt_b_loop:			dq b_loop
	
section .bss
	retstack: 			resq 65536 
	userstack: 			resq 65536
	dictionary			resq 65536
	stackHead:  		resq 1
	ustackHead:  		resq 1
	state:      		resq 1
	branch:				resq 1
	current_word:		resq 256
	
section .text
global _start
_start:
	; Инициализация интерпретатора
	mov [stackHead], rsp
	mov rstack, retstack + 65536*word_size
	mov qword[ustackHead], userstack + 65536*word_size
	mov here, dictionary
	jmp b_loop
	
b_loop:
	mov pc, xt_bootstrap_interpreter_loop
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

section .data
	last_word: dq link 

