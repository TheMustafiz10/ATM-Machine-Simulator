.MODEL SMALL
.STACK 100H
.DATA
    ; Messages
    WELCOME_MSG DB 'Welcome to Multi-User ATM$'
    USER_PROMPT DB 0DH,0AH,'Enter User Number (1-3): $'
    PIN_PROMPT DB 0DH,0AH,'Enter PIN (4 digits): $'
    INVALID_PIN DB 0DH,0AH,'Invalid PIN! Attempts left: $'
    INVALID_USER DB 0DH,0AH,'Invalid User Number! Try again.$'
    MENU_MSG DB 0DH,0AH,'1. Balance Inquiry',0DH,0AH,'2. Withdrawal',0DH,0AH,'3. Deposit',0DH,0AH,'4. Transaction History',0DH,0AH,'5. Logout',0DH,0AH,'6. Exit',0DH,0AH,'Choose option: $'
    BALANCE_MSG DB 0DH,0AH,'Current Balance: $'
    AMOUNT_PROMPT DB 0DH,0AH,'Enter amount: $'
    SUCCESS_MSG DB 0DH,0AH,'Transaction successful!$'
    INSUF_FUNDS DB 0DH,0AH,'Insufficient funds!$'
    INVALID_AMT_MSG DB 0DH,0AH,'Invalid amount! Amount must be greater than 0.$'
    LOGOUT_MSG DB 0DH,0AH,'Logged out successfully.$'
    
    ; User Information
    USER_PINS DW 1234, 5678, 1357  ; PINs for users 1, 2, and 3
    CURRENT_USER DB 0              ; Currently logged in user (1-3)
    ATTEMPTS DB 3                  ; Login attempts
    
    ; Balance for each user
    USER_BALANCES DW 1000, 1000, 1000
    
    ; Transaction History for each user
    TRANS_TYPE1 DB 10 DUP(?)   ; User 1 transaction types
    TRANS_AMT1 DW 10 DUP(?)    ; User 1 transaction amounts
    TRANS_COUNT1 DB 0          ; User 1 transaction count
    
    TRANS_TYPE2 DB 10 DUP(?)   ; User 2 transaction types
    TRANS_AMT2 DW 10 DUP(?)    ; User 2 transaction amounts
    TRANS_COUNT2 DB 0          ; User 2 transaction count
    
    TRANS_TYPE3 DB 10 DUP(?)   ; User 3 transaction types
    TRANS_AMT3 DW 10 DUP(?)    ; User 3 transaction amounts
    TRANS_COUNT3 DB 0          ; User 3 transaction count

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    
    ; Display welcome message
    LEA DX, WELCOME_MSG
    MOV AH, 9
    INT 21H

LOGIN_START:
    MOV ATTEMPTS, 3    ; Reset attempts for new login
    
USER_INPUT:
    ; Prompt for user number
    LEA DX, USER_PROMPT
    MOV AH, 9
    INT 21H
    
    ; Read user number (1-3)
    MOV AH, 1
    INT 21H
    SUB AL, '0'
    
    ; Validate user number
    CMP AL, 1
    JL INVALID_USER_NUM
    CMP AL, 3
    JG INVALID_USER_NUM
    
    MOV CURRENT_USER, AL  ; Store current user
    JMP PIN_INPUT
    
INVALID_USER_NUM:
    LEA DX, INVALID_USER
    MOV AH, 9
    INT 21H
    JMP USER_INPUT
    
PIN_INPUT:
    ; Check if attempts remaining
    CMP ATTEMPTS, 0
    JE LOGIN_START
    
    ; Display PIN prompt
    LEA DX, PIN_PROMPT
    MOV AH, 9
    INT 21H
    
    ; Read PIN
    CALL READ_NUMBER
    
    ; Compare with correct PIN based on current user
    PUSH AX          ; Save entered PIN
    MOV BL, CURRENT_USER
    DEC BL          ; Convert to 0-based index
    MOV BH, 0
    SHL BX, 1       ; Multiply by 2 for word array
    MOV SI, BX
    POP AX          ; Restore entered PIN
    
    CMP AX, USER_PINS[SI]
    JE MAIN_MENU
    
    ; Wrong PIN
    DEC ATTEMPTS
    LEA DX, INVALID_PIN
    MOV AH, 9
    INT 21H
    
    ; Display remaining attempts
    MOV DL, ATTEMPTS
    ADD DL, '0'
    MOV AH, 2
    INT 21H
    
    JMP PIN_INPUT

MAIN_MENU:
    ; Display menu
    LEA DX, MENU_MSG
    MOV AH, 9
    INT 21H
    
    ; Read choice
    MOV AH, 1
    INT 21H
    
    ; Process choice
    CMP AL, '1'
    JE SHOW_BALANCE
    CMP AL, '2'
    JE WITHDRAW
    CMP AL, '3'
    JE DEPOSIT
    CMP AL, '4'
    JE SHOW_HISTORY
    CMP AL, '5'
    JE LOGOUT
    CMP AL, '6'
    JE SAVE_AND_EXIT
    JMP MAIN_MENU

SHOW_BALANCE:
    LEA DX, BALANCE_MSG
    MOV AH, 9
    INT 21H
    
    ; Get current user's balance
    MOV BL, CURRENT_USER
    DEC BL
    MOV BH, 0
    SHL BX, 1
    MOV AX, USER_BALANCES[BX]
    CALL DISPLAY_NUMBER
    
    JMP MAIN_MENU

WITHDRAW:
    LEA DX, AMOUNT_PROMPT
    MOV AH, 9
    INT 21H
    
    CALL READ_NUMBER  ; Amount to withdraw in AX
    
    ; Check if amount is greater than 0
    CMP AX, 0
    JLE INVALID_AMOUNT
    
    ; Get current user's balance index
    PUSH AX          ; Save withdrawal amount
    MOV BL, CURRENT_USER
    DEC BL
    MOV BH, 0
    SHL BX, 1       ; Multiply by 2 for word array
    
    ; Check if sufficient balance
    CMP AX, USER_BALANCES[BX]
    POP AX          ; Restore withdrawal amount
    JG INSUFFICIENT_FUNDS
    
    ; Update balance
    SUB USER_BALANCES[BX], AX
    
    ; Record transaction
    CALL RECORD_WITHDRAWAL
    
    LEA DX, SUCCESS_MSG
    MOV AH, 9
    INT 21H
    JMP MAIN_MENU

DEPOSIT:
    LEA DX, AMOUNT_PROMPT
    MOV AH, 9
    INT 21H
    
    CALL READ_NUMBER  ; Amount to deposit in AX
    
    ; Check if amount is greater than 0
    CMP AX, 0
    JLE INVALID_AMOUNT
    
    ; Get current user's balance index
    PUSH AX          ; Save deposit amount
    MOV BL, CURRENT_USER
    DEC BL
    MOV BH, 0
    SHL BX, 1       ; Multiply by 2 for word array
    POP AX          ; Restore deposit amount
    
    ; Update balance
    ADD USER_BALANCES[BX], AX
    
    ; Record transaction
    CALL RECORD_DEPOSIT
    
    LEA DX, SUCCESS_MSG
    MOV AH, 9
    INT 21H
    JMP MAIN_MENU

INSUFFICIENT_FUNDS:
    LEA DX, INSUF_FUNDS
    MOV AH, 9
    INT 21H
    JMP MAIN_MENU

INVALID_AMOUNT:
    LEA DX, INVALID_AMT_MSG
    MOV AH, 9
    INT 21H
    JMP MAIN_MENU

SHOW_HISTORY:
    CALL DISPLAY_HISTORY
    JMP MAIN_MENU

LOGOUT:
    LEA DX, LOGOUT_MSG
    MOV AH, 9
    INT 21H
    
    JMP LOGIN_START

SAVE_AND_EXIT:
    MOV AH, 4CH
    INT 21H
    
    
    
MAIN ENDP

READ_NUMBER PROC
    ; Read a number and return in AX
    PUSH BX
    PUSH CX
    MOV BX, 0      ; Initialize result to 0
    MOV CX, 0      ; Initialize digit counter
    
READ_DIGIT:
    MOV AH, 1      ; Read a character
    INT 21H
    
    ; Check if it's Enter key (carriage return)
    CMP AL, 0DH
    JE FINISH_READ
    
    ; Check if digit is between 0-9
    CMP AL, '0'
    JL INVALID_DIGIT
    CMP AL, '9'
    JG INVALID_DIGIT
    
    ; Convert ASCII to number
    SUB AL, '0'
    MOV AH, 0
    
    ; Save current digit
    PUSH AX
    
    ; Multiply previous result by 10
    MOV AX, BX
    MOV BX, 10
    MUL BX
    MOV BX, AX
    
    ; Add new digit
    POP AX
    ADD BX, AX
    
    ; Increment counter
    INC CX
    
    ; Check if we've read 4 digits (maximum)
    CMP CX, 4
    JL READ_DIGIT   ; If less than 4 digits, continue reading
    
    ; If 4 digits read, automatically finish
    JMP FINISH_READ
    
INVALID_DIGIT:
    ; Handle invalid input if needed
    JMP READ_DIGIT
    
FINISH_READ:
    MOV AX, BX     ; Move result to AX
    POP CX
    POP BX
    RET
READ_NUMBER ENDP


DISPLAY_NUMBER PROC
    ; Display number in AX
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV BX, 10
    MOV CX, 0
    
DIVIDE:
    MOV DX, 0
    DIV BX
    PUSH DX
    INC CX
    CMP AX, 0
    JNE DIVIDE
    
DISPLAY:
    POP DX
    ADD DL, '0'
    MOV AH, 2
    INT 21H
    LOOP DISPLAY
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DISPLAY_NUMBER ENDP

RECORD_WITHDRAWAL PROC
    PUSH AX
    PUSH BX
    PUSH SI
    
    ; Determine which transaction array to use based on current user
    MOV BL, CURRENT_USER
    CMP BL, 1
    JE USE_TRANS1
    CMP BL, 2
    JE USE_TRANS2
    CMP BL, 3
    JE USE_TRANS3
    JMP RW_EXIT     ; Invalid user, exit
    
USE_TRANS1:
    XOR BX, BX
    MOV BL, TRANS_COUNT1
    MOV SI, BX
    MOV TRANS_TYPE1[SI], 'W'
    SHL BX, 1
    MOV TRANS_AMT1[BX], AX
    INC TRANS_COUNT1
    JMP RW_EXIT
    
USE_TRANS2:
    XOR BX, BX
    MOV BL, TRANS_COUNT2
    MOV SI, BX
    MOV TRANS_TYPE2[SI], 'W'
    SHL BX, 1
    MOV TRANS_AMT2[BX], AX
    INC TRANS_COUNT2
    JMP RW_EXIT
    
USE_TRANS3:
    XOR BX, BX
    MOV BL, TRANS_COUNT3
    MOV SI, BX
    MOV TRANS_TYPE3[SI], 'W'
    SHL BX, 1
    MOV TRANS_AMT3[BX], AX
    INC TRANS_COUNT3
    
RW_EXIT:
    POP SI
    POP BX
    POP AX
    RET
RECORD_WITHDRAWAL ENDP

RECORD_DEPOSIT PROC
    PUSH AX
    PUSH BX
    PUSH SI
    
    ; Determine which transaction array to use based on current user
    MOV BL, CURRENT_USER
    CMP BL, 1
    JE USE_DEP_TRANS1
    CMP BL, 2
    JE USE_DEP_TRANS2
    CMP BL, 3
    JE USE_DEP_TRANS3
    JMP RD_EXIT     ; Invalid user, exit
    
USE_DEP_TRANS1:
    XOR BX, BX
    MOV BL, TRANS_COUNT1
    MOV SI, BX
    MOV TRANS_TYPE1[SI], 'D'
    SHL BX, 1
    MOV TRANS_AMT1[BX], AX
    INC TRANS_COUNT1
    JMP RD_EXIT
    
USE_DEP_TRANS2:
    XOR BX, BX
    MOV BL, TRANS_COUNT2
    MOV SI, BX
    MOV TRANS_TYPE2[SI], 'D'
    SHL BX, 1
    MOV TRANS_AMT2[BX], AX
    INC TRANS_COUNT2
    JMP RD_EXIT
    
USE_DEP_TRANS3:
    XOR BX, BX
    MOV BL, TRANS_COUNT3
    MOV SI, BX
    MOV TRANS_TYPE3[SI], 'D'
    SHL BX, 1
    MOV TRANS_AMT3[BX], AX
    INC TRANS_COUNT3
    
RD_EXIT:
    POP SI
    POP BX
    POP AX
    RET
RECORD_DEPOSIT ENDP

DISPLAY_HISTORY PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    ; Determine which transaction array to use based on current user
    MOV BL, CURRENT_USER
    CMP BL, 1
    JE SHOW_TRANS1
    CMP BL, 2
    JE SHOW_TRANS2
    CMP BL, 3
    JE SHOW_TRANS3
    JMP DH_EXIT     ; Invalid user, exit

SHOW_TRANS1:
    XOR CX, CX
    MOV CL, TRANS_COUNT1
    XOR SI, SI              ; Initialize index to 0
    
SHOW_LOOP1:
    CMP CX, 0
    JE DH_EXIT
    
    ; Display newline
    MOV DL, 0DH
    MOV AH, 2
    INT 21H
    MOV DL, 0AH
    INT 21H
    
    ; Display transaction type
    MOV DL, TRANS_TYPE1[SI]
    MOV AH, 2
    INT 21H
    
    ; Display separator
    MOV DL, ':'
    MOV AH, 2
    INT 21H
    MOV DL, ' '
    INT 21H
    
    ; Calculate offset for amount and display it
    PUSH SI
    SHL SI, 1              ; Multiply by 2 for word array
    MOV AX, TRANS_AMT1[SI] ; Get amount
    CALL DISPLAY_NUMBER
    POP SI
    
    INC SI
    LOOP SHOW_LOOP1
    JMP DH_EXIT

SHOW_TRANS2:
    XOR CX, CX
    MOV CL, TRANS_COUNT2
    XOR SI, SI              ; Initialize index to 0
    
SHOW_LOOP2:
    CMP CX, 0
    JE DH_EXIT
    
    ; Display newline
    MOV DL, 0DH
    MOV AH, 2
    INT 21H
    MOV DL, 0AH
    INT 21H
    
    ; Display transaction type
    MOV DL, TRANS_TYPE2[SI]
    MOV AH, 2
    INT 21H
    
    ; Display separator
    MOV DL, ':'
    MOV AH, 2
    INT 21H
    MOV DL, ' '
    INT 21H
    
    ; Calculate offset for amount and display it
    PUSH SI
    SHL SI, 1              ; Multiply by 2 for word array
    MOV AX, TRANS_AMT2[SI] ; Get amount
    CALL DISPLAY_NUMBER
    POP SI
    
    INC SI
    LOOP SHOW_LOOP2
    JMP DH_EXIT

SHOW_TRANS3:
    XOR CX, CX
    MOV CL, TRANS_COUNT3
    XOR SI, SI              ; Initialize index to 0
    
SHOW_LOOP3:
    CMP CX, 0
    JE DH_EXIT
    
    ; Display newline
    MOV DL, 0DH
    MOV AH, 2
    INT 21H
    MOV DL, 0AH
    INT 21H
    
    ; Display transaction type
    MOV DL, TRANS_TYPE3[SI]
    MOV AH, 2
    INT 21H
    
    ; Display separator
    MOV DL, ':'
    MOV AH, 2
    INT 21H
    MOV DL, ' '
    INT 21H
    
    ; Calculate offset for amount and display it
    PUSH SI
    SHL SI, 1              ; Multiply by 2 for word array
    MOV AX, TRANS_AMT3[SI] ; Get amount
    CALL DISPLAY_NUMBER
    POP SI
    
    INC SI
    LOOP SHOW_LOOP3
    
DH_EXIT:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DISPLAY_HISTORY ENDP

END MAIN
