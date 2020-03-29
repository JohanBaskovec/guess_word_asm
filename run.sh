./build.sh

if [ $? -eq 0 ]; then
    ./word_guess
    exit 0
else
    exit 1
fi

