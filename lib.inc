section .text

; Длина строки
; rdi -- Указатель на строку
; rax -- возвращаемое значение
string_length:
	push rbx
	mov rbx, rdi
	xor rax, rax
	.loop:
		cmp byte[rbx + rax], 0
		je .finish
		inc rax
		jmp .loop
	.finish:
		pop rbx
		ret

; Вывести нуль-терминированную строку из памяти на экран
; rdi -- указатель на строку
print_string:
	mov rsi, rdi
	call string_length
	mov rdx, rax
	mov rax, 1
	mov rdi, 1
	syscall
	ret

; Вывести символ на экран
; rdi -- код выводимого символа
print_char:
	push rcx
	push rax
	push rsi
	push rdx
	push rdi
	mov rax, 1
	mov rdi, 1
	mov rsi, rsp
	mov rdx, 1
	syscall
	pop rdi
	pop rdx
	pop rsi
	pop rax
	pop rcx
	ret

; Вывод переноса строки
print_newline:
	push rdi
	mov rdi, 10
	call print_char
	pop rdi
	ret

; Вывод беззнакового 8-байтного
; rdi -- число для вывода
print_uint:
	mov r9, rsp

	dec rsp
	mov byte[rsp], 0
	
	mov r8, 10
	mov rax, rdi
	.loop:
		xor rdx, rdx
		div r8
		add rdx, 48
		dec rsp
		mov byte[rsp], dl
		test rax, rax
		jnz .loop
	
	mov rdi, rsp
	call print_string
	
	mov rsp, r9
	ret
	
; Вывод знакового 8-байтного
; rdi -- число для вывода
print_int:
	and rdi, rdi
	jns .unsigned
	push rdi
	mov rdi, 45
	call print_char
	pop rdi
	neg rdi
	.unsigned:
		call print_uint
	ret
	
; Сравнение строк
; rax -- 1, если равны
; r8, r9
string_equals:
	push rdi
	push rsi
    xor rax, rax
    xor r8, r8
    xor r9, r9
	.loop:
		mov r8b, byte[rdi]
		mov r9b, byte[rsi]
		cmp r8, r9
		jne .fail
		inc rdi
		inc rsi
		test r8, r8
		jnz .loop
	inc rax
	.fail:
	pop rsi
	pop rdi
    ret

; Чтение символа из stdin
; rsi -- прочитанный символ
read_char: 
	push 0
	xor rax, rax
	xor rdi, rdi
	mov rsi, rsp
	mov rdx, 1
	syscall
	mov al, byte[rsp]
	pop rsi
	ret

section .data
	word_buffer times 256 db 0

section .text

; Пропуск первых пробельных символов и чтение слова до пробельного символа
; rax -- возвращает указатель на строку
; rdx -- длина прочитанного слова
read_word:
	xor r8, r8
	mov r8, word_buffer
	; Чтение до пробельного символа
	.skip:
		call read_char
		test rax, rax
		jz .finish
		cmp rax, 32
		jle .skip
	; Чтение слова
	.read_next:
		mov [r8], rax
		inc r8
		call read_char
		cmp rax,  32
		jg .read_next
		; Вычисление длины строки и возврат результат
	.finish:
		mov rdi, word_buffer
		call string_length
		mov rdx, rax
		mov rax, word_buffer
    ret

; rdi points to a string
; returns rax: number, rdx : length
parse_uint:
	push rdi
    xor rax, rax
    xor rdx, rdx
    xor r10, r10
    mov r8, 10
	.loop:
		cmp byte[rdi], 48
		jl .finish
		cmp byte[rdi], 57
		jg .finish
		inc r10
		mul r8
		xor r9, r9
		mov r9b, byte[rdi]
		sub r9, 48
		add rax, r9
		inc rdi
		jmp .loop
		
	.finish:
		mov rdx, r10
	pop rdi
    ret

; rdi points to a string
; returns rax: number, rdx : length
parse_int:
    xor rax, rax
    cmp byte[rdi], 45
    je .sign
	call parse_uint
	ret
	.sign:
		inc rdi
		call parse_uint
		neg rax
		inc rdx
	.finish:
    ret 


string_copy:
	push rcx
	.loop:
		xor rcx, rcx
		mov cl, byte[rdi]
		mov byte[rsi], cl
		inc rdi
		inc rsi
		test rcx, rcx
		jnz .loop
	pop rcx
	ret
