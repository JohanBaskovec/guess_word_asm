#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#include <stdbool.h>

#define TO_STRING(x) STR(x)
#define STR(x) #x

#define GUESS_MAX_SIZE 100

int get_random_word(char *word) {
    int ret = 0;
    puts("Trying to read words.txt...");

    FILE *file = fopen("words.txt", "r");
    if (!file) {
        perror("The file words.txt doesn't exist or can't be opened");
        ret = 1;
        goto end;
    }

    int n_words = 0;
    int c;
    while((c = fgetc(file)) != EOF) {
        if ((char)c == '\n') {
            n_words++;
        }
    }
    if (n_words == 0) {
        printf("words.txt is empty.");
        ret = 1;
        goto end;
    } else if (ferror(file)) {
        puts("I/O error when reading");
        ret = 1;
        goto end;
    } else if (feof(file)) {
        printf("words.txt has been read successfully, %d words in the file.\n\n",
                n_words);
    }
    rewind(file);

    int word_index = rand() % n_words;
#ifdef WG_DEBUG
        printf("Word index to guess: %d\n", word_index);
#endif

    int scan_result;
    int i = 0;
    while (true) {
        scan_result = fscanf(file, " %" TO_STRING(GUESS_MAX_SIZE) "s", word);
        if (scan_result == EOF) {
            perror("Failed reading words.txt");
            ret = 1;
            goto end;
        }
        if (i == word_index) {
            break;
        }
        i++;
    }

end:
    fclose(file);
    return ret;
}

void guess_word(char *word) {
    int word_length = strlen(word);

    char guessed_word[word_length + 1];
    printf("Guess the word (%d characters)\n", word_length);
    for (int i = 0 ; i < word_length ; i++) {
        guessed_word[i] = '_';
    }
    guessed_word[word_length] = 0;
    bool has_guessed_word = false;
    int chars_left = word_length;
    char guess[GUESS_MAX_SIZE];
    int health = 10;

    while (!has_guessed_word && health > 0) {
#ifdef WG_DEBUG
        printf("Word to guess: %s\n", word);
#endif
        printf("Health: %d\n", health);
        printf("%s\n", guessed_word);
        printf("\n");

        scanf(" %" TO_STRING(GUESS_MAX_SIZE) "s", guess);
        bool already_guessed_char = false;
        for (int i = 0 ; i < word_length ; i++) {
            if (guessed_word[i] == guess[0]) {
                already_guessed_char = true;
                printf("You already guessed this letter.\n");
            }
        }
        if (already_guessed_char) {
            continue;
        }

        if (strlen(guess) == 1) {
            bool found = false;
            for (int i = 0 ; i < word_length ; i++) {
                if (word[i] == guess[0]) {
                    chars_left--;
                    guessed_word[i] = guess[0];
                    found = true;
                }
            }
            if (found) {
                printf("Correct guess!\n");
            } else {
                printf("Wrong guess!\n");
                health--;
            }
            if (chars_left == 0) {
                has_guessed_word = true;
            }
        } else {
            if (strcmp(guess, word) == 0) {
                printf("Correct guess!\n");
                has_guessed_word = true;
            } else {
                printf("Wrong guess!\n");
                health--;
            }
        }
    }

    if (health > 0) {
        puts("You won!");
    } else {
        puts("You lost!");
    }
}

int main() {
    srand(time(NULL));

    char word[GUESS_MAX_SIZE+1];
    int err = get_random_word(word);
    if (err) {
        return err;
    }
    guess_word(word);
}
