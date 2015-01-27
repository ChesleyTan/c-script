    /* =============== DEFINITIONS ============= */
%token BOOLEAN INTEGER FLOAT VARIABLE STRING INT_ARRAY STRING_ARRAY
%token IF ENDIF ELSE WHILE
    /* Left-associative operator precedence */
%left '+' '-'
%left GTE LTE EQL NEQ AND OR
%left '*' '/' '<' '>' '|' '^'
%left '(' ')' '[' ']' '{' '}'
    /* Right-associative operator precedence */
%right '%' '#'
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
    char boolval;
    char *strval;
    char **str_arrayval;
    int intval;
    int *int_arrayval;
    float floatval;
}

%type <boolval> BOOLEAN
%type <strval> STRING
%type <strval> str_expr
%type <boolval> bool_expr
%type <str_arrayval> STRING_ARRAY
%type <str_arrayval> str_array_expr
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
		 | bool_expr			{ printf("%d\n", $1); }
         | expr                 { printf("%d\n", $1); }
         | float_expr           { printf("%f\n", $1); }
         | str_expr             { printf("%s\n", $1); free($1); }
         | int_array_expr       {
                                    printf("{");
                                    int i = 1;
                                    while(i < $1[0]) {
                                        printf("%d", $1[i]);
                                        if (++i < $1[0]) {
                                            printf(", ");
                                        }
                                    }
                                    printf("}\n");
                                    free($1);
                                }
         | str_array_expr       {
                                    printf("{");
                                    int i = 0;
                                    while($1[i]) {
                                        printf("%s", $1[i]);
                                        free($1[i]);
                                        if ($1[++i]) {
                                            printf(", ");
                                        }
                                    }
                                    printf("}\n");
                                    free($1);
                                }
         | VARIABLE '=' expr    { sym[$1] = $3; }
         ;
		
bool_expr:
		   BOOLEAN					{ $$ = $1 }
		 | bool_expr OR bool_expr { $$ = $1 || $3 }
		 | expr OR bool_expr 		{ $$ = $1 || $3 }
		 | bool_expr OR expr 		{ $$ = $1 || $3 }
		 | expr OR expr 			{ $$ = $1 || $3 }
		 | bool_expr AND bool_expr { $$ = $1 && $3 }
		 | expr AND bool_expr 		{ $$ = $1 && $3 }
		 | bool_expr AND expr 		{ $$ = $1 && $3 }
		 | expr AND expr 			{ $$ = $1 && $3 }
		 | bool_expr EQL bool_expr { $$ = $1 == $3 }
		 | expr EQL bool_expr 		{ $$ = $1 == $3 }
		 | bool_expr EQL expr 		{ $$ = $1 == $3 }
		 | expr EQL expr 			{ $$ = $1 == $3 }
		 | expr '>' expr			{ $$ = $1 > $3 }
		 | bool_expr '>' expr		{ $$ = $1 > $3 }
		 | expr '>' bool_expr		{ $$ = $1 > $3 }
		 | bool_expr '>' bool_expr	{ $$ = $1 > $3 }
		 | expr '<' expr			{ $$ = $1 < $3 }
		 | bool_expr '<' expr		{ $$ = $1 < $3 }
		 | expr '<' bool_expr		{ $$ = $1 < $3 }
		 | bool_expr LTE bool_expr	{ $$ = $1 < $3 }
		 | expr GTE expr			{ $$ = $1 >= $3 }
		 | bool_expr GTE expr		{ $$ = $1 >= $3 }
		 | expr GTE bool_expr		{ $$ = $1 >= $3 }
		 | bool_expr GTE bool_expr	{ $$ = $1 >= $3 }
		 | expr LTE expr			{ $$ = $1 <= $3 }
		 | bool_expr LTE expr		{ $$ = $1 <= $3 }
		 | expr LTE bool_expr		{ $$ = $1 <= $3 }
		 | bool_expr LTE bool_expr	{ $$ = $1 <= $3 }

expr:
           INTEGER                  { $$ = $1; }
         | VARIABLE                 { $$ = sym[$1]; }
         | expr '+' expr            { $$ = $1 + $3; }
		 | bool_expr '+' expr		{ $$ = $1 + $3; }
		 | expr '+' bool_expr		{ $$ = $1 + $3; }
		 | bool_expr '+' bool_expr  { $$ = $1 + $3; }
         | expr '-' expr            { $$ = $1 - $3; }
		 | bool_expr '-' expr		{ $$ = $1 - $3; }
		 | expr '-' bool_expr		{ $$ = $1 - $3; }
		 | bool_expr '-' bool_expr  { $$ = $1 - $3; }
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
         | '#' str_array_expr       {

            int i = 0;
            while ($2[i]) {
                free($2[i]);
                ++i;
            }
            free($2);
            $$ = i;

                                    }
         | int_array_expr '[' expr ']'          {

                if ($3 >= 0 && $3 < $1[0] - 1) {
                    $$ = $1[$3 + 1];
                }
                else {
                    print_error("Array index out of bounds.");
                    $$ = 0;
                }

                                                }
         ;
str_expr:
           STRING                   { $$ = $1; }
         | str_expr '+' str_expr    {

            char *s = (char *) malloc(sizeof(char) *
                (strlen($1) + strlen($3) + 1));
            if (s != NULL) {
                strcpy(s, $1);
                strcat(s, $3);
            }
            else {
                print_error("Out of memory.");
            }
            free($1);
            free($3);
            $$ = s;

                                    }
         | expr '*' str_expr    {

            char *s;
            if ($1 > 0) {
                s = (char *) malloc(sizeof(char) * $1 * strlen($3) + 1);
                if (s != NULL) {
                    int count = 1;
                    strcpy(s, $3);
                    while (count++ < $1) {
                        strcat(s, $3);
                    }
                }
                else {
                    print_error("Out of memory.");
                }
            }
            else {
                s = (char *) malloc(sizeof(char));
                if (s != NULL) {
                    s[0] = '\0';
                }
                else {
                    print_error("Out of memory.");
                }
            }
            free($3);
            $$ = s;

                                }
         | str_expr '*' expr    {

            char *s;
            if ($3 > 0) {
                s = (char *) malloc(sizeof(char) * $3 * strlen($1) + 1);
                if (s != NULL) {
                    int count = 1;
                    strcpy(s, $1);
                    while (count++ < $3) {
                        strcat(s, $1);
                    }
                }
                else {
                    print_error("Out of memory.");
                }
            }
            else {
                s = (char *) malloc(sizeof(char));
                if (s != NULL) {
                    s[0] = '\0';
                }
                else {
                    print_error("Out of memory.");
                }
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
                if (s != NULL) {
                    /* Copy substring before match */
                    strncpy(s, $1, match - $1);
                    /* Copy substring after match */
                    strcpy(s+(int)(match - $1), match + match_len);
                }
                else {
                    print_error("Out of memory.");
                }
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
            if (s != NULL) {
                snprintf(s, 100, "%s%d", $1, $3);
            }
            else {
                print_error("Out of memory.");
            }
            free($1);
            $$ = s;

                                    }
         | expr '+' str_expr        {

            char *s = (char *) malloc(sizeof(char) * (strlen($3) + 100));
            if (s != NULL) {
                snprintf(s, 100, "%d%s", $1, $3);
            }
            else {
                print_error("Out of memory.");
            }
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
                if (s != NULL) {
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
                }
                else {
                    print_error("Out of memory.");
                }
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
         | str_array_expr '[' expr ']'      {

            /*
            * Use int, rather than size_t for
            * correct signed to signed comparison
            */
            int len = str_arrlen($1);
            if (len > 0) {
                int index = $3;
                if ($3 >= 0 && $3 < len) {
                    $$ = $1[$3];
                }
                else {
                    print_error("Array index out of bounds.");
                    index = 0;
                    $$ = $1[index];
                }
                /* Free dynamically allocated memory */
                int i;
                for (i = 0;i < index;++i) {
                    free($1[i]);
                }
                for (i = index + 1;i < len;++i) {
                    free($1[i]);
                }
                free($1);
            }
            else {
                $$ = $1[0];
                free($1);
            }
                                            }
         ;

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
              | int_array_expr '+' int_array_expr   {

        int *i = (int *) malloc(sizeof(int) * ($1[0] + $3[0] + 1));
        if (i != NULL) {
            int i_index = 0;
            int t_index = 0;
            i[0] = $1[0] + $3[0] - 1;
            while (++i_index < $1[0]) {
                i[i_index] = $1[++t_index];
            }
            i_index = $1[0] - 1;
            t_index = 0;
            while (++t_index < $3[0]) {
                i[++i_index] = $3[t_index];
            }
        }
        else {
            print_error("Out of memory.");
        }
        free($1);
        free($3);
        $$ = i;

                                                    }
              | int_array_expr '+' expr             {

        int *i = (int *) malloc(sizeof(int) * ($1[0] + 1));
        if (i != NULL) {
            i[0] = $1[0] + 1;
            int p;
            for (p = 1;p < $1[0];++p) {
                i[p] = $1[p];
            }
            i[$1[0]] = $3;
            free($1);
            $$ = i;
        }
        else {
            print_error("Out of memory.");
            $$ = $1;
        }

                                                    }
              | int_array_expr '-' expr             {

        int match = -1;
        int p;
        for (p = 1;p < $1[0];++p) {
            if ($1[p] == $3) {
                // Match position includes 0 index
                match = p;
            }
        }
        if (match != -1) {
            #ifdef DEBUG
            print_debug("Found match at %d", match);
            #endif
            int *i = (int *) malloc(sizeof(int) * ($1[0] - 1));
            if (i != NULL) {
                i[0] = $1[0] - 1;
                for (p = 1;p < match;++p) {
                    i[p] = $1[p];
                }
                for (p = match;p < $1[0] - 1;++p) {
                    i[p] = $1[p + 1];
                }
                free($1);
                $$ = i;
            }
            else {
                print_error("Out of memory.");
            }
        }
        else {
            #ifdef DEBUG
            print_debug("No match.");
            #endif
            $$ = $1;
        }

                                                    }
              | int_array_expr '*' expr   {

        if ($3 >= 0) {
            int *i = (int *) malloc(sizeof(int) * (($1[0] - 1) * $3 + 1));
            if (i != NULL) {
                int mult = 0;
                int p = 0;
                i[0] = ($1[0] - 1) * $3 + 1;
                printf("New array of size %d\n", i[0]);
                while (++mult <= $3) {
                    int q;
                    for (q = 1;q < $1[0];++q) {
                        i[++p] = $1[q];
                    }
                }
                free($1);
                $$ = i;
            }
            else {
                print_error("Out of memory.");
                $$ = $1;
            }
        }
        else {
            print_error("Cannot multiply array by negative integer.");
            $$ = $1;
        }

                                                    }
            | '(' int_array_expr ')'               { $$ = $2; }
        ;
str_array_expr:
                STRING_ARRAY                       { $$ = $1; }
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
        if (s != NULL) {
            s[0] = '\0';
        }
        else {
            print_error("Out of memory.");
        }
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
        if (s != NULL) {
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
        }
        else {
            print_error("Out of memory.");
        }
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
