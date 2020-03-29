./build_c.sh

if [ $? -eq 0 ]; then
    ./word_guess_c

    echo "Exit with code" $?
else
    echo Build failed.
fi
