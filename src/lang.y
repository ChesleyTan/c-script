    /* =============== DEFINITIONS ============= */
%token INTEGER FLOAT VARIABLE STRING
    /* Left-associative operator precedence */
%left '+' '-'
%left '*' '%'
%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <errno.h>
    #include <string.h>
    #include <math.h>

    #include "utils.h"

    void yyerror(char *);
    int yylex(void);
    int sym[26];
    extern FILE * yyin;
    extern int yylineno;
%}

%union {
    char *strval;
    int intval;
    float floatval;
}

%type <strval> STRING
%type <strval> str_expr
%type <intval> VARIABLE
%type <intval> expr
%type <intval> INTEGER
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
         | expr '*' str_expr     {
                                        char *s;
                                        if ($1 > 0) {
                                            s = (char *) malloc(sizeof(char) *
                                                $1 * strlen($3) + 1);
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
         | str_expr '*' expr     {
                                        char *s;
                                        if ($3 > 0) {
                                            s = (char *) malloc(sizeof(char) *
                                                $3 * strlen($1) + 1);
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
                                            char *s = (char *)
                                                malloc(sizeof(char) *
                                                (strlen($1) - match_len + 1));
                                            /* Copy substring before match */
                                            strncpy(s, $1, match - $1);
                                            /* Copy substring after match */
                                            strcpy(s+(int)(match - $1),
                                                match + match_len);
                                            free($1);
                                            free($3);
                                            $$ = s;
                                        }
                                        else {
                                            free($3);
                                            $$ = $1;
                                        }
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
%%
    /* ================ END RULES ================ */

    /* ================ SUBROUTINES ============== */
void yyerror(char *s) {
    fprintf(stderr, "Line %d: %s\n", yylineno, s);
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
