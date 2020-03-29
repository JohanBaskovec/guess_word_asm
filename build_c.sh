clang -g -o word_guess_c word_guess.c -D WG_DEBUG -std=c11


if [ $? -eq 0 ]; then
    chmod +x ./word_guess_c
    exit 0
else
    exit 1
fi
