section .text

; Ищет слово в словаре
; rdi -- ссылка на слово
; rax -- адрес начала слова
find_word:
	xor rax, rax
	mov rsi, [last_word]
	.loop:
		push rsi
		add rsi, 8
		call string_equals
		pop rsi
		
		test rax, rax
		jnz .finish
		mov rsi, [rsi]
		test rsi, rsi
		jnz .loop 
		xor rax, rax
		ret
	.finish:
		mov rax, rsi		
	ret
	
; compiler mode
; native block
native '+', plus
	mov rax, rsp
	add rax, 1*word_size
	cmp rax, [stackHead]
	jge error_underflow
	pop rax
	add [rsp], rax
	jmp next
	
native '-', minus
	mov rax, rsp
	add rax, 1*word_size
	cmp rax, [stackHead]
	jge error_underflow
	pop rax
	sub [rsp], rax
	jmp next
	
native '*', multiple
	mov rax, rsp
	add rax, 1*word_size
	cmp rax, [stackHead]
	jge error_underflow
	pop rax
	pop rcx
	imul rcx
	push rax
	jmp next
	
native '/', division
	mov rax, rsp
	add rax, 1*word_size
	cmp rax, [stackHead]
	jge error_underflow
	pop rcx
	pop rax
	cqo
	idiv rcx
	push rax
	jmp next
	
native '=', equals
	mov rax, rsp
	add rax, 1*word_size
	cmp rax, [stackHead]
	jge error_underflow
	pop rax
	pop rcx
	cmp rax, rcx
	sete al
	movzx rax, al
	push rax
	jmp next
	
native '<', less
	mov rax, rsp
	add rax, 1*word_size
	cmp rax, [stackHead]
	jge error_underflow
	pop rax
	pop rcx
	cmp rcx, rax
	setl al
	movzx rax, al
	push rax
	jmp next
	
native 'and', log_and
	mov rax, rsp
	add rax, 1*word_size
	cmp rax, [stackHead]
	jge error_underflow
	pop rax
	pop rcx
	and rax, rcx
	cmp rax, 0
	setne al
	movzx rax, al
	push rax
	jmp next
	
native 'not', negation
	cmp rsp, [stackHead]
	jge error_underflow
    pop     rax
    test    rax, rax
    setne   al
    movzx   rax, al
    push    rax
    jmp     next
	
native 'rot', rot
	mov rax, rsp
	add rax, 2*word_size
	cmp rax, [stackHead]
	jge error_underflow
	pop rcx
	pop rdx
	pop rax
	push rdx
	push rax
	push rcx
	jmp next
	
native 'swap', swap_stack
	mov rax, rsp
	add rax, 1*word_size
	cmp rax, [stackHead]
	jge error_underflow
	pop rax
	pop rcx
	push rax
	push rcx
	jmp next
	
native 'dup', dup
	cmp rsp, [stackHead]
	jge error_underflow
	pop rax
	push rax
	push rax
	jmp next
	
native 'drop', drop
	cmp rsp, [stackHead]
	jge error_underflow
	pop rax
	jmp next
	
native '.', dot
	cmp rsp, [stackHead]
	jge error_underflow
	pop rdi
	call print_int
	call print_newline
	jmp next
	
native 'key', key
	call read_char
	push rdi
	jmp next
	
native 'emit', emit
	cmp rsp, [stackHead]
	jge error_underflow
	pop rdi
	call print_char
	jmp next
	
native 'number', number
	call read_word
	mov rax, rdi
	call parse_int
	push rax
	jmp next
	
native 'mem', mem
	push qword[ustackHead]
	jmp next
	
native '@', data_read
	cmp rsp, [stackHead]
	jge error_underflow
	pop rax
	mov rax, [rax]
	push rax
	jmp next
	
native '!', data_write
	mov rax, rsp
	add rax, 1*word_size
	cmp rax, [stackHead]
	jge error_underflow
	pop rax
	pop rdx
	mov [rax], rdx
	jmp next
	
native '.S', show_stack
	mov rax, rsp
	.loop:
		cmp rax, [stackHead]
		jge next
		mov rdi, [rax]
		push rax
		call print_int
		call print_newline
		pop rax
		add rax, 8
		jmp .loop
	

native 'exit', close
	jmp close
	
; colon block
colon '>', more
	dq xt_swap_stack
	dq xt_less
	dq xt_exit
	
colon 'or', log_or
    dq      xt_negation
    dq      xt_swap_stack
    dq      xt_negation
    dq      xt_log_and
    dq      xt_negation
    dq      xt_exit
    
; compiler mode
native ':', col, 1
	mov byte[state], 1
	mov rdi, [last_word]
	mov [here], rdi
	mov qword[last_word], here 
	add  here, word_size
	call read_word
	mov rdi, rax
	mov rsi, here
	call string_copy
	mov here, rsi
	inc here
	mov qword[here], docol
	add here, word_size
	jmp next
	
native ';', semicolon, 1
	mov byte[state], 0
	mov qword[here], xt_exit
	add here, word_size
	jmp next

native 'lit', lit
    push    qword[pc]
    add     pc, word_size
    jmp     next
    
native 'branch', branch, 2
	mov rax, qword[pc]
	inc rax
	mov rcx, word_size
	mul rcx
	add pc, rax
	jmp next
	
native 'branch0', branch0, 2
	pop rcx
	;push rcx
	test rcx, rcx
	jnz .finish
	jmp branch_impl
	.finish:
	add pc, word_size
	jmp next
	

; bootstrap section
native ',', comma
	pop rax
	mov qword[here], rax
	add here, word_size
	jmp next
	
native 'word', wordreader
	call read_word
	pop rsi
	push rdx
	mov rdi, rax
	call string_copy
	jmp next
	
native 'create', create_word
	mov rdi, [last_word]
	mov [here], rdi
	mov qword[last_word], here 
	add  here, word_size
	pop rdi
	mov rsi, here
	call string_copy
	mov here, rsi
	inc here
	mov qword[here], docol
	add here, word_size
	jmp next
	
native 'find', find
	pop rdi
	call find_word
	push rax
	jmp next
	
native 'cfa', cfa
	xor rax, rax
	pop rdi
	add rdi, word_size
	.loop:
		mov al, [rdi]
		test al, al
		jz .finish
		inc rdi
		jmp .loop
	.finish:
		add rdi, 2
		push rdi
		mov dil, [rdi-1]
		and rdi, 0xFF
		push rdi
	jmp next

; Выводит на экран строку, адрес которой на вершине стека
native 'write', write
	pop rdi
	call print_string
	jmp next
	
; выполняет команду по адресу, который на вершине стека
native 'exec', exec
	pop rax
	mov w, rax
	mov [program_stub], rax
	mov pc, program_stub
	jmp next
	
native 'parse', parse
	pop rdi
	call parse_int
	push rax
	push rdx
	jmp next
	
; получить xt по слову
colon '"', get_xt
	dq xt_lit
	dq word_buffer
	dq xt_dup
	dq xt_wordreader
	dq xt_drop
	dq xt_find
	dq xt_branch0
	dq 1
	dq xt_cfa
	dq xt_exit
	
; data block
section .data
	;xt_docol: dq docol
	xt_exit: dq exit
	
; error handling block
error_underflow:
	mov rdi, underflow
	call print_string
	jmp next
	
; Начало всех colon-слов
docol:
	sub rstack, 8
	mov [rstack], pc
	add w, 8
	mov pc, w
	jmp next
	
; конец всех colon-слов
exit:
	mov pc, [rstack]
	add rstack, 8
	jmp next
	
