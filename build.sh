nasm -f elf64 -g -F dwarf -l word_guess.lst word_guess.asm

if [ $? -eq 0 ]; then
    clang -g -o word_guess word_guess.o

    if [ $? -eq 0 ]; then
        chmod +x ./word_guess
        exit 0
    else
        exit 1
    fi
else
    exit 1
fi

