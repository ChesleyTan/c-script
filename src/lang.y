    /* =============== DEFINITIONS ============= */
%token INTEGER VARIABLE STRING
    /* Left-associative operator precedence */
%left '+' '-'
%left '*' '%'
%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <errno.h>
    #include <string.h>

    #include "utils.h"

    void yyerror(char *);
    int yylex(void);
    int sym[26];
    extern FILE * yyin;
%}

%union {
    char *strval;
    int intval;
}

%type <strval> STRING
%type <strval> str_expr
%type <intval> VARIABLE
%type <intval> expr
%type <intval> INTEGER
    /* ============= END DEFINITIONS ============= */

    /* ================== RULES ================== */
%%
program:
          program statement '\n'
        |
        ;

statement:
           expr                 { printf("%d\n", $1); }
         | str_expr             { printf("%s\n", $1); free($1); }
         | VARIABLE '=' expr    { sym[$1] = $3; }
         ;
expr:
           INTEGER              { $$ = $1; }
         | VARIABLE             { $$ = sym[$1]; }
         | expr '+' expr        { $$ = $1 + $3; }
         | expr '-' expr        { $$ = $1 - $3; }
         | expr '*' expr        { $$ = $1 * $3; }
         | expr '/' expr        { $$ = $1 / $3; }
         | '(' expr ')'         { $$ = $2; }
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
         | INTEGER '*' str_expr     {
                                        char *s = (char *) malloc(sizeof(char) *
                                            $1 * strlen($3) + 1);
                                        int count = 1;
                                        strcpy(s, $3);
                                        while (count++ < $1) {
                                            strcat(s, $3);
                                        }
                                        free($3);
                                        $$ = s;
                                    }
%%
    /* ================ END RULES ================ */

    /* ================ SUBROUTINES ============== */
void yyerror(char *s) {
    fprintf(stderr, "%s\n", s);
}

int main(int argc, char*argv[]) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (yyin == NULL) {
            print_errno("Could not open file for reading.");
        }
    }
    yyparse();
    return 0;
}
    /* ============= END SUBROUTINES ============= */
