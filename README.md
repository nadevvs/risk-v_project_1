## Map

- **main**
  - **input_loop**
    - print prompt
    - read input line
    - set cursor `s3`
    - **token loop**
      - **skip_spaces**
        - whitespace → advance cursor
        - end-of-line → read next line
      - **process_token**
        - `.` → exit
        - `=` → handle_equals
        - `+ * /` → handle_operator
        - `-`
          - digit follows → parse_integer
          - otherwise → handle_operator
        - number → parse_integer
