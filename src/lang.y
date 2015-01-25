    /* =============== DEFINITIONS ============= */
%token INTEGER VARIABLE STRING
    /* Left-associative operator precedence */
%left '+' '-'
%left '*' '%'
%{
    #include <stdio.h>
    void yyerror(char *);
    int yylex(void);
    int sym[26];
%}

%union {
    char *strval;
    int intval;
}

%type <strval> STRING
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
         expr                   { printf("%d\n", $1); }
         | STRING               { printf("%s\n", $1); }
         | VARIABLE '=' expr    { sym[$1] = $3; }
         ;
expr:
         INTEGER                { $$ = $1; }
         | VARIABLE             { $$ = sym[$1]; }
         | expr '+' expr        { $$ = $1 + $3; }
         | expr '-' expr        { $$ = $1 - $3; }
         | expr '*' expr        { $$ = $1 * $3; }
         | expr '/' expr        { $$ = $1 / $3; }
         | '(' expr ')'         { $$ = $2; }
         ;
%%
    /* ================ END RULES ================ */

    /* ================ SUBROUTINES ============== */
void yyerror(char *s) {
    fprintf(stderr, "%s\n", s);
}

int main(int argc, char*argv[]) {
    yyparse();
    return 0;
}
    /* ============= END SUBROUTINES ============= */
