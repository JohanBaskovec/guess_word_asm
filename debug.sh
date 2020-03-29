./build.sh


if [ $? -eq 0 ]; then
    gdb word_guess

    echo "Exit with code" $?
fi
