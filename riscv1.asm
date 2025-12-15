.data
    .align 2
input_buffer:      .space 256
prompt_msg:        .asciz "\n> "
newline:           .asciz "\n"
error_div_zero:    .asciz "Error: Division by zero\n"
error_underflow:   .asciz "Error: Missing operand)))\n"
    .align 2
stack_base:        .word 0 

.text
.globl main

# s3 = input c pointer
# s0 = result / parsed int
# t0 = curr char / operator
# t1, t2 = operands
# t6 = init stack pointer 

main:
    la  t6, stack_base
    sw  sp, 0(t6)

input_loop:
    li  a7, 4
    la  a0, prompt_msg
    ecall

    li  a7, 8
    la  a0, input_buffer
    li  a1, 256
    ecall

    la  s3, input_buffer

line_token_loop:
skip_spaces:
    lbu t0, 0(s3)

    beq t0, zero, input_loop     

    li  t1, 0x0A                
    beq t0, t1, input_loop       

    li  t1, ' '
    beq t0, t1, adv_char
    li  t1, '\t'
    beq t0, t1, adv_char
    li  t1, '\r'
    beq t0, t1, adv_char

    j process_token

adv_char:
    addi s3, s3, 1
    j skip_spaces

process_token:
    lbu t0, 0(s3)

    li  t1, '.'
    beq t0, t1, exit_program

    li  t1, '='
    beq t0, t1, handle_equals

    li  t1, '+'
    beq t0, t1, handle_operator

    li  t1, '-'
    beq t0, t1, minus_maybe_number

    li  t1, '*'
    beq t0, t1, handle_operator

    li  t1, '/'
    beq t0, t1, handle_operator

    j parse_integer


minus_maybe_number:
    lbu t2, 1(s3)               
    li  t3, '0'
    blt t2, t3, handle_operator
    li  t3, '9'
    bgt t2, t3, handle_operator
    j   parse_integer

parse_integer:
    li  s0, 0                    
    li  t1, 0                    

    lbu t0, 0(s3)
    li  t2, '-'
    bne t0, t2, digit_parse_start
    li  t1, 1
    addi s3, s3, 1               

digit_parse_start:
parse_digit:
    lbu t0, 0(s3)
    li  t3, '0'
    blt t0, t3, finish_parse
    li  t3, '9'
    bgt t0, t3, finish_parse

    li  t3, 10
    mul s0, s0, t3
    addi t0, t0, -48
    add s0, s0, t0

    addi s3, s3, 1
    j parse_digit

finish_parse:
    beq t1, zero, push_value
    neg s0, s0

push_value:
    addi sp, sp, -4
    sw   s0, 0(sp)
    j    skip_spaces


handle_equals:
    la  t6, stack_base
    lw  t6, 0(t6)
    beq sp, t6, underflow_equals

    lw  s0, 0(sp)
    addi sp, sp, 4

    mv  a0, s0
    li  a7, 1                    
    ecall

    li  a0, 10
    li  a7, 11                   
    ecall

    addi s3, s3, 1               
    j    skip_spaces

underflow_equals:
    li  a7, 4
    la  a0, error_underflow
    ecall
    addi s3, s3, 1
    j    skip_spaces

handle_operator:
    
    la  t6, stack_base
    lw  t6, 0(t6)
    addi t6, t6, -8              

    bltu sp, t6, pop_and_dispatch
    
    beq  sp, t6, pop_and_dispatch

    j underflow_op

pop_and_dispatch:
    lw   t1, 0(sp)              
    addi sp, sp, 4
    lw   t2, 0(sp)              
    addi sp, sp, 4

    li   t3, '+'
    beq  t0, t3, do_add
    li   t3, '-'
    beq  t0, t3, do_sub
    li   t3, '*'
    beq  t0, t3, do_mul
    li   t3, '/'
    beq  t0, t3, do_div

    j next_after_op

underflow_op:
    li  a7, 4
    la  a0, error_underflow
    ecall
    addi s3, s3, 1              
    j    skip_spaces

do_add:
    add s0, t2, t1
    j   push_result

do_sub:
    sub s0, t2, t1               
    j   push_result

do_mul:
    mul s0, t2, t1
    j   push_result

do_div:
    beq  t1, zero, div_by_zero
    div  s0, t2, t1             
    j    push_result

div_by_zero:
    li  a7, 4
    la  a0, error_div_zero
    ecall
    addi sp, sp, -4
    sw   t2, 0(sp)
    addi sp, sp, -4
    sw   t1, 0(sp)
    j next_after_op

push_result:
    addi sp, sp, -4
    sw   s0, 0(sp)

next_after_op:
    addi s3, s3, 1              
    j    skip_spaces



exit_program:
    li a7, 10
    ecall
