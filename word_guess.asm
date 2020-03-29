extern printf,scanf,puts,scanf,perror
extern strcmp,strlen
extern rand,srand,time
extern exit
extern fopen,ferror,feof,fscanf,fgetc,rewind,fclose
extern memset

segment .data
a       dq  54
b       dq  43

%define main_menu_start 's'
%define main_menu_options 'o'
%define READ 'r'
%define WORDS_FILE "words.txt"

%define quot '"'
%define stringify(x) quot %+ x %+ quot
%define MAX_WORD_SIZE 128 ; multiple of 16 to keep stack aligned
%define MAX_WORD_SIZE_STR "128";stringify(MAX_WORD_SIZE)

main_menu:
.menu               db `Welcome.\n`,main_menu_start,`-Start\n`,main_menu_options,`-Options\n\0`
.scan               db ` %c\0`
.echo_selection     db `Selected %c\n\0`
.invalid_selection  db `Invalid.\n\0`

game:
.welcome            db `Welcome.\n\0`

options:
.welcome            db `Welcome to the options (WIP).\n\0`

read_mode_str       db READ,0

get_random_word_str:
.intro:             db `Trying to read `,WORDS_FILE,`...\0`
.file_name          db WORDS_FILE,0
.read_success       db `words.txt has been read successfully, %d words in the file.\n\n\0`
.read_fail          db `The file `,WORDS_FILE,` doesn't exist or can't be opened\0`
.no_words           db WORDS_FILE,` is empty.\0`
.io_error           db `I/O error when reading\0`
.word_scan          db ` %`,MAX_WORD_SIZE_STR,`s\0`
.debug_word_index   db `Word index to guess: %d\n\0`

guess_str_debug_print_word   db `Word to guess: %s\n\0`
guess_str_health             db `Health: %d\n\0`
guess_str_guessed_word       db `%s\n\0`
guess_str_scanf              db ` %128s\0`
guess_str_already_guessed    db `You already guessed this letter.\n\0`
guess_str_correct            db `Correct guess.\0`
guess_str_wrong              db `Wrong guess.\0`
guess_str_won                db `You won!\0`
guess_str_lost               db `You lost!\0`

segment .text
global main

start:
    enter   0,0
    mov     rdi,game.welcome
    xor     eax,eax
    call    printf

    sub     rsp,MAX_WORD_SIZE-16 ; word size + 16 bytes for 0
    mov     rdi,rsp     ; address of the array for the word on the stack
    call    get_random_word

    mov     rdi,rsp
    call    guess_word

    leave
    ret

guess_word:
    enter   32+MAX_WORD_SIZE+1+MAX_WORD_SIZE+15,0
    mov     [rsp],qword r12   ; r12 = address of word
    mov     [rsp+8],qword r13 ; r13 = word length
    mov     [rsp+16],qword r14; r14 = health
    mov     [rsp+24],qword r15; r15 = chars left to guess
    guessed_word equ         32
    guess        equ         guessed_word + MAX_WORD_SIZE + 1

    mov     r12,rdi
    call    strlen
    mov     r13,rax
    lea     rdi,[rsp+guessed_word]
    mov     rsi,'_'
    mov     rdx,r13
    call    memset
    mov     [rsp+guessed_word+r13],byte 0    ; final 0 char of string

    mov     r14,qword 10      ; health
    mov     r15,r13     ; chars left to guess

    .guess_loop:
        xor     rax,rax
        mov     rdi,guess_str_debug_print_word
        mov     rsi,r12
        call    printf

        xor     rax,rax
        mov     rdi,guess_str_health
        mov     rsi,r14
        call    printf

        xor     rax,rax
        mov     rdi,guess_str_guessed_word
        lea     rsi,[rsp+guessed_word]
        call    printf

        xor     rax,rax
        mov     rdi,guess_str_scanf
        lea     rsi,[rsp+guess]
        call    scanf

        lea     rdi,[rsp+guess]
        call    strlen
        cmp     rax,1
        jne     .word_guess
        xor     r9,r9       ; char was found
        .single_char_guess:
            xor     r11,r11 ; i
            mov     r10b, byte[rsp+guess] ; r10b = input char
            .loop_over_chars:
                cmp     byte [rsp+guessed_word+r11], byte r10b
                je      .already_guessed_char
                cmp     byte [r12+r11], r10b
                jne     .increment_and_loop
                mov     byte [rsp+guessed_word+r11], byte r10b
                dec     r15     ; decrements chars left to guess
                cmp     r15,0   ; if no more chars left, user won, end game
                je     .guess_loop_end
                mov     r9,1    ; char found flag
                .increment_and_loop:
                    inc     r11
                    cmp     r11,r13
                    jne     .loop_over_chars
                    cmp     r9, 1   ; if r9 == 1, char was found, guess another
                    je      .char_in_word
                    mov     rdi,guess_str_wrong
                    call    puts
                    dec     r14     ;char isn't in the word, decrease health
                    cmp     r14, 0
                    je      .guess_loop_end ;no more health, user lost, end game
                    jmp     .guess_loop
                    .char_in_word:
                    mov     rdi,guess_str_correct
                    call    puts
                    jmp     .guess_loop

            .already_guessed_char:
                mov     rdi,guess_str_already_guessed
                call    puts
                jmp     .guess_loop

        .word_guess:
            lea     rdi,[rsp+guess]
            mov     rsi,r12
            call    strcmp
            cmp     rax,0
            je      .words_equal
            mov     rdi,guess_str_wrong
            call    puts
            dec     r14
            cmp     r14, 0
            je      .guess_loop_end ;no more health, user lost, end game
            jmp     .guess_loop

            .words_equal:
                mov     rdi,guess_str_correct
                call    puts
                jmp     .guess_loop_end

    .guess_loop_end:
    cmp     r14,0
    jne     .won
    mov     rdi,guess_str_lost
    call    puts

    .won:
    mov     rdi,guess_str_won
    call    puts



    mov     r12,qword [rsp]
    mov     r13,qword [rsp+8]
    mov     r14,qword [rsp+16]
    mov     r15,qword [rsp+24]
    leave
    ret

display_options:
    enter   0,0
    mov     rdi,options.welcome
    xor     eax,eax
    call    printf
    leave
    ret

get_random_word:
    return_val  equ 0

    enter   32,0    ; pushes rbp to the stack, aligning it to 16 bytes
    ; r12, r13, r14 and r15 are callee-saved
    mov     [rsp],qword r12   ; r12 = file pointer
    mov     [rsp+8],qword r13 ; r13 = number of words in file, i in loop to get word
    mov     [rsp+16],qword r14; r14 = word index
    mov     [rsp+24],qword r15; r15 = address of word array
    mov     r15,rdi
    xor     rax,rax ; return value 0 = no error
    mov     rdi,get_random_word_str.intro
    call    puts
    mov     rdi,get_random_word_str.file_name
    mov     rsi,read_mode_str
    call    fopen
    mov     r12,rax ; r12 = file pointer
    cmp     rax,0
    jne     .fopen_success
    ;fopen failed:
    mov     rdi,get_random_word_str.read_fail
    call    puts
    mov     rax,1   ; error code 1
    jmp    .leave

    .fopen_success:
    xor     r13,r13     ; r13 = n_words = 0
    .count_words:
    mov     rdi,r12
    call    fgetc       ; rax = fgetc()
    cmp     rax,-1      ; if rax == EOF, stop reading
    je      .stop_counting_words
    cmp     rax,`\n`    ; if rax == '\n', increase r13 (n_words)
    jne     .count_words
    inc     r13
    jmp     .count_words

    .stop_counting_words:
    cmp     r13,0       ; no words found
    jne     .maybe_error
    mov     rdi,get_random_word_str.no_words
    call    puts
    mov     rax,1   ; error code 1
    jmp     .leave

    .maybe_error:
    mov     rdi,r12
    call    ferror
    cmp     rax,0
    je     .fgetc_success
    mov     rdi,get_random_word_str.io_error
    call    puts
    mov     rax,1   ; error code 1
    jmp     .leave

    .fgetc_success:
    mov     rdi,get_random_word_str.read_success
    mov     rsi,r13
    call    printf

    mov     rdi,r12
    call    rewind

    ; generate a random index
    call    rand

    mov     edx,0
    div     r13         ; rdx = rax%r13
    mov     r14,rdx     ; r14 = rdx = reminder = word_index
    mov     rdi,get_random_word_str.debug_word_index
    mov     rsi,r14
    xor     rax,rax
    call    printf

    xor     r13,r13     ; i
    .read_lines:
    xor     eax,eax     ; no floating point arguments
    mov     rdi,r12     ; file
    mov     rsi,get_random_word_str.word_scan   ; format string
    mov     rdx,r15     ; address of target string

    call    fscanf
    cmp     r14,r13     ; if (i == word_index)
    je     .found_word
    inc     r13
    jmp     .read_lines
    .found_word:

    .leave:
    mov     rdi,r12
    call    fclose
    mov     r12,qword [rsp]
    mov     r13,qword [rsp+8]
    mov     r14,qword [rsp+16]
    mov     r15,qword [rsp+24]
    leave
    ret

show_menu:
    enter           16,0     ; push rbp to the stack, aligning it to 16 bytes
    menu_selection  equ 0

    .loop_until_selected:
        ; print menu
        mov     rdi,main_menu.menu
        xor     eax,eax
        call    printf

        ; scan character option
        mov     rdi,main_menu.scan
        mov     rsi,rsp+menu_selection
        call    scanf

        ; print back selection
        xor     eax,eax
        mov     rdi,main_menu.echo_selection
        mov     sil,byte [rsp+menu_selection]
        call    printf

        ; jump to selected option's label
        mov     sil,byte [rsp+menu_selection]
        cmp     sil,byte main_menu_start
        je      .start
        cmp     sil,byte main_menu_options
        je      .options

        ; if invalid selection, display warning and display the menu again
        xor     eax,eax
        mov     rdi,main_menu.invalid_selection
        call    printf
        jmp     .loop_until_selected

    .start:
        call    start
        jmp     .leave
    .options:
        call    display_options
        jmp     .leave
    .leave:
        leave
        ret

main:
    enter   0,0         ; push rbp to the stack
    xor     rdi,rdi
    call    time        ; rax = time(NULL)
    mov     rdi,rax
    call    srand       ; srand(rax) (= srand(time(NULL))
    ;call    show_menu
    ;call    get_random_word
    call    start
    xor     rax,rax
    leave
    ret
