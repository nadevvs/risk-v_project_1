main
 └─ input_loop  (repeat forever)
     ├─ print prompt
     ├─ read a whole line into input_buffer
     ├─ s3 = start of input_buffer
     └─ line_token_loop
         └─ skip_spaces (scanner)
             ├─ if end-of-line → back to input_loop
             ├─ if whitespace → adv_char → skip_spaces
             └─ process_token
                 ├─ '.' → exit_program
                 ├─ '=' → handle_equals
                 ├─ '+' '*' '/' → handle_operator
                 ├─ '-' → minus_maybe_number
                 │        ├─ next char digit → parse_integer
                 │        └─ else → handle_operator
                 └─ otherwise → parse_integer

parse_integer
 ├─ read optional leading '-'
 ├─ accumulate digits into s0
 └─ push_value (push s0 on stack)

handle_operator
 ├─ underflow check (need 2 operands)
 ├─ pop op2 then op1
 ├─ dispatch:
 │    ├─ do_add / do_sub / do_mul / do_div
 │    └─ (div by zero handled)
 ├─ push_result
 └─ next_after_op (advance s3)

handle_equals
 ├─ underflow check (need 1 operand)
 ├─ pop value
 ├─ print value + newline
 └─ advance s3

exit_program
 └─ terminate via ecall 10
