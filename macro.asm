%define link 0
%define word_size 8

; Перегрузка native 3
%macro native 2
native %1, %2, 0
%endmacro

; native имя слова, часть идентификатора, флаги
%macro native 3
section .data
w_ %+ %2:
    %%link dq link
%define link %%link
    db %1, 0
    db %3
xt_ %+ %2:
    dq %2 %+ _impl
section .text
%2 %+ _impl:
%endmacro

%macro colon 2
colon %1, %2, 0
%endmacro

%macro colon 3
section .data
w_ %+ %2:
    %%link dq link
%define link %%link
    db %1, 0
    db %3
xt_ %+ %2:
	dq docol
%endmacro

