.data
    .align 2
input_buffer:      .space 256
prompt_msg:        .asciz "\n> "
error_div_zero:    .asciz "Error: Division by zero\n"
error_underflow:   .asciz "Error: Missing operand\n"

    .align 2
eval_stack:        .space 4096          # separate memory stack: 1024 ints
eval_stack_end:                          # label = address after the stack

.text
.globl main

# Register plan:
# s3 = input cursor (pointer into input_buffer)
# s4 = eval stack base address
# s5 = eval stack top pointer (points to next free slot)
# s0 = general result / parsed integer
# t0 = current character (token's first char)
# t1,t2 = operands

main:
    la  s4, eval_stack          # base
    la  s5, eval_stack          # top = base (empty)

input_loop:
    li  a7, 4
    la  a0, prompt_msg
    ecall

    li  a7, 8
    la  a0, input_buffer
    li  a1, 256
    ecall

    la  s3, input_buffer

skip_spaces:
    lbu t0, 0(s3)

    beq t0, zero, input_loop     # end of string -> next line
    li  t1, 0x0A                 # '\n'
    beq t0, t1, input_loop       # newline -> next line

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
    beq t0, t1, op_plus

    li  t1, '-'
    beq t0, t1, minus_maybe_number

    li  t1, '*'
    beq t0, t1, op_mul

    li  t1, '/'
    beq t0, t1, op_div

    j parse_integer

minus_maybe_number:
    lbu t2, 1(s3)                # peek next char
    li  t3, '0'
    blt t2, t3, op_minus
    li  t3, '9'
    bgt t2, t3, op_minus
    j   parse_integer

op_plus:
    li  a0, 1
    j   apply_operator
op_minus:
    li  a0, 2
    j   apply_operator
op_mul:
    li  a0, 3
    j   apply_operator
op_div:
    li  a0, 4
    j   apply_operator

parse_integer:
    li  s0, 0                    # value
    li  t1, 0                    # sign flag: 0=+, 1=-

    lbu t0, 0(s3)
    li  t2, '-'
    bne t0, t2, digit_parse_start
    li  t1, 1
    addi s3, s3, 1               # skip '-'

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
    mv  a0, s0
    jal ra, stack_push           # push a0
    j   skip_spaces

handle_equals:
    jal ra, stack_pop            # returns a0=value, a1=ok(1)/underflow(0)
    beqz a1, underflow_equals

    # print int
    li  a7, 1
    ecall
    # newline char
    li  a0, 10
    li  a7, 11
    ecall

    addi s3, s3, 1               # skip '='
    j    skip_spaces

underflow_equals:
    li  a7, 4
    la  a0, error_underflow
    ecall
    addi s3, s3, 1
    j    skip_spaces

apply_operator:
    mv  t6, a0                   # save opCode in t6

    jal ra, stack_pop
    beqz a1, underflow_op
    mv  t1, a0                   # op2

    jal ra, stack_pop
    beqz a1, underflow_op_restore1
    mv  t2, a0                   # op1

    li  t0, 1
    beq t6, t0, do_add
    li  t0, 2
    beq t6, t0, do_sub
    li  t0, 3
    beq t6, t0, do_mul
   
    j do_div

underflow_op:
    li  a7, 4
    la  a0, error_underflow
    ecall
    addi s3, s3, 1             
    j    skip_spaces

underflow_op_restore1:
    mv  a0, t1
    jal ra, stack_push
    j   underflow_op

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
    beq t1, zero, div_by_zero
    div s0, t2, t1              
    j   push_result

div_by_zero:
    li  a7, 4
    la  a0, error_div_zero
    ecall
    
    mv  a0, t2
    jal ra, stack_push
    mv  a0, t1
    jal ra, stack_push

    addi s3, s3, 1           
    j    skip_spaces

push_result:
    mv  a0, s0
    jal ra, stack_push

    addi s3, s3, 1              
    j    skip_spaces

stack_push:
    sw  a0, 0(s5)
    addi s5, s5, 4
    ret

stack_pop:
    beq s5, s4, stack_underflow
    addi s5, s5, -4
    lw  a0, 0(s5)
    li  a1, 1
    ret
stack_underflow:
    li  a0, 0
    li  a1, 0
    ret

exit_program:
    li a7, 10
    ecall
