    /* =============== DEFINITIONS ============= */
%token INTEGER FLOAT VARIABLE STRING INT_ARRAY
    /* Left-associative operator precedence */
%left '+' '-'
%left '*' '%'
%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <unistd.h>
    #include <signal.h>
    #include <errno.h>
    #include <sys/wait.h>
    #include <string.h>
    #include <math.h>
    #include <readline/readline.h>
    #include <readline/history.h>

    #include "utils.h"

    #define INPUT_BUF_SIZE 2048
    #define EOF_EXIT_CODE 10
    #define SIGINT_EXIT_CODE 11

    void yyerror(char *);
    int yylex(void);
    extern FILE * yyin;
    extern int yylineno;

    int sym[26];
    char keep_alive = 1;
    char input[INPUT_BUF_SIZE];
    int rl_child_pid;
    const char *prompt = ">> ";

    static void readline_sigint_handler();
    static void sighandler(int signo);
    char * substring(char *str, int b1, int b2, int step);

%}

%union {
    char *strval;
    int intval;
    float floatval;
    int *int_arrayval;
}

%type <strval> STRING
%type <strval> str_expr
%type <intval> VARIABLE
%type <intval> expr
%type <intval> INTEGER
%type <int_arrayval> INT_ARRAY
%type <int_arrayval> int_array_expr
%type <floatval> FLOAT
%type <floatval> float_expr
    /* ============= END DEFINITIONS ============= */

    /* ================== RULES ================== */
%%
program:
          program statement '\n'
        |
        ;

statement:
         | expr                 { printf("%d\n", $1); }
         | float_expr           { printf("%f\n", $1); }
         | str_expr             { printf("%s\n", $1); free($1); }
         | int_array_expr       {
                                    printf("[");
                                    int i = 1;
                                    while(i < $1[0]) {
                                        printf("%d", $1[i]);
                                        if (++i < $1[0]) {
                                            printf(", ");
                                        }
                                    }
                                    printf("]\n");
                                    free($1);
                                }
         | VARIABLE '=' expr    { sym[$1] = $3; }
         ;
expr:
           INTEGER                  { $$ = $1; }
         | VARIABLE                 { $$ = sym[$1]; }
         | expr '+' expr            { $$ = $1 + $3; }
         | expr '-' expr            { $$ = $1 - $3; }
         | expr '*' expr            { $$ = $1 * $3; }
         | expr '/' expr            {

            if ($3 != 0)
                $$ = $1 / $3;
            else
                $$ = 0;

                                    }
         | expr '%' expr            {

            if ($3 != 0)
                $$ = $1 % $3;
            else
                $$ = 0;

                                    }
         | expr '*''*' expr         { $$ = (int) powf($1, $4); }
         | expr '^' expr            { $$ = $1 ^ $3; }
         | expr '|' expr            { $$ = $1 | $3; }
         | expr '>''>' expr         { $$ = $1 >> $4; }
         | expr '<''<' expr         { $$ = $1 << $4; }
         | '(' expr ')'             { $$ = $2; }
         | '#' str_expr             { $$ = strlen($2); free($2); }
         | str_expr '[' str_expr ']'    {
                                            char *ptr = strstr($1, $3);
                                            if (ptr != NULL) {
                                                $$ = ptr - $1;
                                            }
                                            else {
                                                $$ = -1;
                                            }
                                            free($1);
                                            free($3);
                                        }
         | '#' int_array_expr       { $$ = $2[0] - 1; free($2); }
         ;
str_expr:
           STRING                   { $$ = $1; }
         | str_expr '+' str_expr    {

            char *s = (char *) malloc(sizeof(char) *
                (strlen($1) + strlen($3) + 1));
            strcpy(s, $1);
            strcat(s, $3);
            free($1);
            free($3);
            $$ = s;

                                    }
         | expr '*' str_expr    {

            char *s;
            if ($1 > 0) {
                s = (char *) malloc(sizeof(char) * $1 * strlen($3) + 1);
                int count = 1;
                strcpy(s, $3);
                while (count++ < $1) {
                    strcat(s, $3);
                }
            }
            else {
                s = (char *) malloc(sizeof(char));
                s[0] = '\0';
            }
            free($3);
            $$ = s;

                                }
         | str_expr '*' expr    {

            char *s;
            if ($3 > 0) {
                s = (char *) malloc(sizeof(char) * $3 * strlen($1) + 1);
                int count = 1;
                strcpy(s, $1);
                while (count++ < $3) {
                    strcat(s, $1);
                }
            }
            else {
                s = (char *) malloc(sizeof(char));
                s[0] = '\0';
            }
            free($1);
            $$ = s;

                                }
         | str_expr '-' str_expr     {

            char *match = strstr($1, $3);
            if (match != NULL) {
                size_t match_len = strlen($3);
                /* Allocate memory for result */
                char *s = (char *) malloc(sizeof(char) *
                    (strlen($1) - match_len + 1));
                /* Copy substring before match */
                strncpy(s, $1, match - $1);
                /* Copy substring after match */
                strcpy(s+(int)(match - $1), match + match_len);
                free($1);
                free($3);
                $$ = s;
            }
            else {
                free($3);
                $$ = $1;
            }

                                    }
         | str_expr '+' expr        {

            char *s = (char *) malloc(sizeof(char) * (strlen($1) + 100));
            snprintf(s, 100, "%s%d", $1, $3);
            free($1);
            $$ = s;

                                    }
         | expr '+' str_expr        {

            char *s = (char *) malloc(sizeof(char) * (strlen($3) + 100));
            snprintf(s, 100, "%d%s", $1, $3);
            free($3);
            $$ = s;

                                    }
         | str_expr '[' expr ']'    {

            /*
                * Use int, rather than size_t for
                * correct signed to signed comparison
                */
            int len = strlen($1);
            if (len > 0) {
                char *s = (char *) calloc(2, sizeof(char));
                int index = $3;
                index %= len;
                if (index < 0) {
                    s[0] = $1[len + index];
                }
                else {
                    s[0] = $1[index];
                }
                free($1);
                s[1] = '\0';
                $$ = s;
            }
            else {
                $$ = $1;
            }

                                    }
         | str_expr '[' expr ':' expr ']'   {

            $$ = substring($1, $3, $5, 1);

                                            }
         | str_expr '[' ':' expr ']'        {

            $$ = substring($1, 0, $4, 1);

                                            }
         | str_expr '[' expr ':' ']'        {

            $$ = substring($1, $3, strlen($1), 1);

                                            }
         | str_expr '[' expr ':' expr ':' expr ']'  {

            $$ = substring($1, $3, $5, $7);

                                                    }
         | str_expr '[' ':' expr ':' expr ']'       {

            $$ = substring($1, 0, $4, $6);

                                                    }
         | str_expr '[' expr ':' ':' expr ']'       {

            $$ = substring($1, $3, strlen($1), $6);

                                                    }
         | str_expr '[' ':' ':' expr ']'            {

            $$ = substring($1, 0, strlen($1), $5);

                                                    }
         | '(' str_expr ')'         { $$ = $2; }
float_expr:
           FLOAT                            { $$ = $1; }
         | float_expr '+' float_expr        { $$ = $1 + $3; }
         | float_expr '+' expr              { $$ = $1 + $3; }
         | expr '+' float_expr              { $$ = $1 + $3; }
         | float_expr '-' float_expr        { $$ = $1 - $3; }
         | float_expr '-' expr              { $$ = $1 - $3; }
         | expr '-' float_expr              { $$ = $1 - $3; }
         | float_expr '*' float_expr        { $$ = $1 * $3; }
         | float_expr '*' expr              { $$ = $1 * $3; }
         | expr '*' float_expr              { $$ = $1 * $3; }
         | float_expr '/' float_expr        {

            if ($3 != 0)
                $$ = $1 / $3;
            else
                $$ = 0;

                                            }
         | float_expr '/' expr              {

            if ($3 != 0)
                $$ = $1 / $3;
            else
                $$ = 0;

                                            }
         | expr '/' float_expr              {

            if ($3 != 0)
                $$ = $1 / $3;
            else
                $$ = 0;

                                            }
         | float_expr '*''*' float_expr     { $$ = powf($1, $4); }
         | float_expr '*''*' expr           { $$ = powf($1, $4); }
         | expr '*''*' float_expr           { $$ = powf($1, $4); }
         | '(' float_expr ')'               { $$ = $2; }
         ;
int_array_expr:
                INT_ARRAY                   { $$ = $1; }
%%
    /* ================ END RULES ================ */

    /* ================ SUBROUTINES ============== */
static void readline_sigint_handler() {
    // Exit gracefully when killed with SIGINT
    exit(SIGINT_EXIT_CODE);
}

static void sighandler(int signo) {
    if (signo == SIGINT) {
        if (rl_child_pid) {
            // Kill readline process to refresh prompt
            kill(rl_child_pid, SIGINT);
        }
    }
}

char * substring(char *str, int b1, int b2, int step) {
    /*
    * Use int, rather than size_t for
    * correct signed to signed comparison
    */
    /*
    * Exclusive of second bound if
    * ascending; Inclusive otherwise
    */
    /* Prevent negative step */
    if (step < 0) {
        print_error("Step size must be positive; To reverse, change the bounds.");
        char *s = (char *) malloc(sizeof(char));
        s[0] = '\0';
        return s;
    }
    int len = strlen(str);
    if (len > 0) {
        int bound1 = b1 % len;
        int bound2 = b2 % (len + 1);
        char isAscending = 0;
        if (bound1 < 0) {
            bound1 = len + bound1;
        }
        if (bound2 < 0) {
            bound2 = len + bound2;
        }
        if (bound1 < bound2) {
            bound2 -= 1;
            isAscending = 1;
        }
        #ifdef DEBUG
        if (!isAscending && bound1 == bound2) {
            print_debug("Substring from %d to %d (Exclusive)",
                bound1, bound2);
        }
        else {
            print_debug("Substring from %d to %d (Inclusive)",
                bound1, bound2);
        }
        #endif
        char *s = (char *) malloc(sizeof(char) *
            ((abs(bound1 - bound2) + 1) / step) + 1);
        int s_index = 0;
        if (bound1 < bound2 || (isAscending && bound1 == bound2)) {
            s[s_index++] = str[bound1];
            bound1 += step;
            while (bound1 < bound2 ||
            (isAscending == 1 && bound1 == bound2)) {
                s[s_index++] = str[bound1];
                bound1 += step;
            }
        }
        else if (bound1 > bound2) {
            s[s_index++] = str[bound1];
            bound1 -= step;
            while (bound1 >= bound2) {
                s[s_index++] = str[bound1];
                bound1 -= step;
            }
        }
        s[s_index++] = '\0';
        free(str);
        return s;
    }
    else {
        return str;
    }
}

void yyerror(char *s) {
    fprintf(stderr, "Line %d: %s\n", yylineno, s);
}

int main(int argc, char*argv[]) {
    signal(SIGINT, sighandler);
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (yyin == NULL) {
            print_errno("Could not open file for reading.");
        }
        yyparse();
    }
    else {
        while(keep_alive) {
            int pipes[2];
            int history_pipes[2];
            if (pipe(pipes) < 0) {
                print_error("Could not open pipe for REPL.");
                exit(1);
            }
            if (pipe(history_pipes) < 0) {
                print_error("Could not open pipe for command history.");
            }
            // Pipe input into Bison
            yyin = fdopen(pipes[0], "r");
            // Fork process for readline
            rl_child_pid = fork();
            if (!rl_child_pid) {
                signal(SIGINT, readline_sigint_handler);
                close(pipes[0]);
                close(history_pipes[0]);
                char *line = readline(prompt);
                if (line == NULL) {
                    printf("\n[Reached EOF]\n");
                    // Free dynamically allocated memory before exiting
                    free(line);
                    // Close pipes before exiting
                    close(pipes[1]);
                    close(history_pipes[1]);
                    exit(EOF_EXIT_CODE);
                }
                size_t read_size = strlen(line);
                // Reallocate line buffer to make space for a newline
                ++read_size;
                char *new_ptr = realloc(line, sizeof(char) * read_size + 1);
                if (new_ptr == NULL) {
                    print_error("Out of memory.");
                }
                line = new_ptr;
                // Add newline to line buffer
                line[read_size - 1] = '\n';
                line[read_size] = '\0';
                // Limit write size to INPUT_BUF_SIZE
                size_t write_size = (INPUT_BUF_SIZE > read_size)
                                    ? read_size : INPUT_BUF_SIZE;
                // Write input to pipe -> Bison
                write(pipes[1], line, write_size);
                // Write input to pipe -> readline history
                write(history_pipes[1], line, write_size);
                // Free dynamically allocated memory before exiting
                free(line);
                // Close pipes before exiting
                close(pipes[1]);
                close(history_pipes[1]);
                exit(0);
            }
            else {
                int status;
                waitpid(rl_child_pid, &status, 0);
                if (WIFEXITED(status)) {
                    status = WEXITSTATUS(status);
                    // Exit if EOF reached
                    if (status == EOF_EXIT_CODE) {
                        // Close pipes before exiting
                        close(pipes[0]);
                        close(pipes[1]);
                        close(history_pipes[0]);
                        close(history_pipes[1]);
                        // Clear readline's history
                        clear_history();
                        exit(0);
                    }
                    // Prepare for re-displaying prompt
                    else if (status == SIGINT_EXIT_CODE) {
                        // Close pipes before relooping
                        close(pipes[0]);
                        close(pipes[1]);
                        close(history_pipes[0]);
                        close(history_pipes[1]);
                        // Go to new line before relooping
                        write(STDOUT_FILENO, "\n", 1);
                        continue;
                    }
                }
                close(pipes[1]);
                close(history_pipes[1]);
                // Read user input for adding to history
                int bytes = read(history_pipes[0], input, INPUT_BUF_SIZE);
                close(history_pipes[0]);
                // Overwrite newline with NULL
                input[bytes - 1] = '\0';
                // Add the input to readline's history
                add_history(input);
                yyparse();
                close(pipes[0]);
            }
        }
    }
    return 0;
}
    /* ============= END SUBROUTINES ============= */
