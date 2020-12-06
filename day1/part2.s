	.text
	.align 2
	.global _main ;_main is the entry point
_main:
	stp fp, lr, [sp, #-16] ;  preserve frame pointer and link register
	sub sp, sp, #16 ; stash the return
	sub sp, sp, #1024 ; put 1kb on the stack why not
	mov x0, sp
	mov x1, #1
	mov x2, #1024
	adrp x3, ___stdinp@GOTPAGE
	ldr x3, [x3, ___stdinp@GOTPAGEOFF]
	ldr x3, [x3]
	bl _fread ; fread ()
	; add a null-terminator, because I'm nice like that
	add x0, sp, x0
	strb wzr, [x0, #0]
	mov x1, sp
	;sub x0, x0, x1
; parse the file contents into an array of numbers
	; inputs
	; x0 = buffer + buf_len
	; sp = buffer
	; x1 = c
	; x2 = var
	; x3 = random arithmetic
	; x4 = array_len
	; x5 = *c
	; x6 = literal '\n' (10)
	; x7 = array
parse_input_loop:
	mov x5, #0
	mov x6, #10 ; new_word = c
	mov x7, sp ; array = sp
	mov x4, #0 ; array_len = 0
	mov x2, #0
parse_loop:
	cmp x1, x0 		; if c == buffer + buf_len
	b.eq parse_finish 	; { break; }
	ldrb w5, [x1] 		; (x5 = *c)
	add x1, x1, #1  	; ++c
	cmp w5, #10 		; if *c == '\n'
	b.eq parse_newline 	; goto newline-processing
;parse_digit:
	sub x3, x5, #48 	; x3 = (long) *c - '0'
	madd x2, x2, x6, x3  	; var = (var * 10) + (*c - '0')
	b parse_loop
parse_newline:
	sub x7, x7, #8  ; push new item onto front of array
	str x2, [x7] 	; array[0] = var
	add x4, x4, #1 	; ++array_len
	mov x2, #0	; var = 0
	b parse_loop
parse_finish: 	; okay we need to fix the stack pointer now
	mov x1, sp 		; x1 = buffer
	and sp, x7, 0xFFFFFFFFFFFFFFF0 	; keep it 16-byte aligned!
	sub sp, sp, #16         ; make space for the stack pointer... on the stack
	str x1, [sp] 		; store the stack pointer (input buffer)

	; triple for loop
	; x7 = array
	; x4 = array + [array_len]
	; x1 = i
	; x2 = j
	; x3 = k
	; x9 = *i
	; x10 = *j
	; x11 = *k
	
	lsl x4, x4, #3 ; x4 = array + (array_len * 8)
	add x4, x4, x7
	sub x1, x7, #8 ; i = array
reset_loop0:
	add x1, x1, #8
begin_loop0:
	cmp x1, x4
	b.ge not_found
	ldr x9, [x1]
	mov x2, x1
reset_loop1:
	add x2, x2, # 8 ; j = i+1
begin_loop1:
	cmp x2, x4
	b.ge reset_loop0
	ldr x10, [x2]
	mov x3, x2
reset_loop2:
	add x3, x3, # 8 ; k = j+1
begin_loop2:
	cmp x3, x4
	b.ge reset_loop1
	ldr x11, [x3]
; do addition check
	add x0, x9, x10
	add x0, x0, x11
	cmp x0, #2020
	b.eq calculate_product
	add x3, x3, #8
	b begin_loop2
not_found:
	adrp x0, _fail.str@PAGE
	add x0, x0, _fail.str@PAGEOFF
	bl _printf
	b cleanup

calculate_product:
	mul x0, x9, x10
	mul x0, x0, x11
	
; output product
	sub sp, sp, #16		; allocate va_list for printf call
	str x0, [sp]
	adrp x0, _printf.str@PAGE
	add x0, x0, _printf.str@PAGEOFF
	bl _printf
	add sp, sp, #16		; pop va_list

cleanup:

	ldr x0, [sp] 		; pop array
	mov sp, x0
;exit_main:
	add sp, sp, #1024 	; pop buffer allocation
	ldp fp, lr, [sp], #16 	; restore frame pointer and link register
	mov x0, #0 		; return 0
	ret
_printf.str:
	.asciz "%d"
	.align 2
_fail.str:
	.asciz "not found!\n"
;l
;l	; using a bitfield as a constant-time lookup for our stack
;l	sub x0, sp, #256	; clear, then allocate bitfield (256 is the 16-byte aligned version of 252, which is 2020/8)
;l	mov x1, sp
;lclear_bitfield:
;l	str xzr, [x0]
;l	add x0, x0, #8
;l	cmp x0, x1
;l	b.ne clear_bitfield
;l	sub sp, sp, #256
;l
;l	; logic goes here
;l	; x1 = bitfield
;l	mov x1, sp
;l
;l	; setting loop:
;l	; foreach i in array
;l	;   set_bit(i, bitfield)
;l	; testing loop:
;l	; foreach i in array (until len-1)
;l	;  foreach j from (i+1) to end
;l	;   test
;l	mov 
;lsetting_loop:
;l	;mov x0
;l	
;l	;cleanup
;l
;l	add sp, sp, #256 	; pop bitfield
; get_bit(long bit_addr, void *bitfield): long
	.align 2
get_bit:
	add x19, x1, x0, lsr 6 	; x19 = bitfield[bit_addr >> 6]
	ldr x19, [x19]		;
	and x0, x0, 0x3F		; x19 >> (bit_addr >> 6] | (1 << (bit_addr & 0x3F))
	lsr x0, x19, x0
	and x0, x0, 0x01
	ret

	.align 2
; set_bit(long bit_addr, long *bitfield)
set_bit:
	add x19, x1, x0, lsr 6 	; x19 = &bitfield[bit_addr >> 6]
	ldr x20, [x19]		;
	mov x21, #1
	and x0, x0, 0x3F		; bitfield[bit_addr >> 6] | (1 << (bit_addr & 0x3F))
	lsl x0, x21, x0
	orr x0, x0, x20
	str x0, [x19]
	ret
nop
