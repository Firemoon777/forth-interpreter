%define pc r15
%define w  r14
%define rstack r13
%define here rbx

%include 'lib.inc'
%include 'macro.asm'
%include 'dict.asm'

section .data
    program_stub:       dq 0
xt_bootstrap_interpreter_loop:
	; Проверка режима работы
	dq xt_lit
	dq state
	dq xt_data_read
	dq xt_branch0 
	dq 2
	dq xt_branch
	dq 28
	; Основной цикл 
    dq xt_lit
	dq current_word
	dq xt_dup
	dq xt_wordreader
	dq xt_drop
	dq xt_find
	dq xt_dup
	dq xt_branch0 ; Если слова нет в словаре, то переходим к обработке цифр
	dq 7
; Выполнение команды
	dq xt_cfa
	dq xt_lit
	dq 2
	dq xt_less
	dq xt_branch0
	dq 8
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
; Цикл компилятора
xt_bootstrap_compiler_loop:
	; основной цикл
	dq xt_lit
	dq current_word
	dq xt_dup
	dq xt_wordreader
	dq xt_drop
	dq xt_find
	dq xt_dup
	dq xt_branch0 ; Если слова нет в словаре, то обработка числа
	dq 10
; Проверка слова на флаг 1
	dq xt_cfa
	dq xt_lit
	dq 1
	dq xt_minus
	dq xt_branch0 ; Если установлен флаг 1, то исполнение
	dq 2
; Компиляция
	dq xt_comma
	dq xt_b_loop
; Исполнение
	dq xt_exec
	dq xt_b_loop
; Обработка числа
	dq xt_drop
	dq xt_lit
	dq current_word
	dq xt_parse
	dq xt_branch0 ; неизвестное слово
	dq 5
	
	; Предыдущее слово не branch*
	dq xt_lit
	dq xt_lit
	dq xt_comma
	dq xt_comma
	dq xt_b_loop
; Неизвестное слово
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

