    /* =============== DEFINITIONS ============= */
%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <sys/types.h>

    #include "colors.h"
    #include "lang.tab.h"

    #define ERRMSG_LENGTH 100
    #define BUF_SIZE 100

    void yyerror(char *);
    char buf[BUF_SIZE];
    // TODO dynamic string size
    size_t buf_index;
%}

    /* Parse state for strings */
%x STRING_STATE 
    /* ============= END DEFINITIONS ============= */

    /* ================== RULES ================== */
%%
    /* ================ Variables ================ */
[a-z]           {
                    yylval.intval = *yytext - 'a';
                    return VARIABLE;
                }
    /* =========================================== */
    /* ================ Integers ================= */
[0-9]+          {
                    yylval.intval = atoi(yytext);
                    return INTEGER;
                }
    /* =========================================== */
    /* ================ Strings ================== */
\"              { BEGIN STRING_STATE; buf_index = 0; }
<STRING_STATE>\\n   { buf[buf_index++] = '\n'; }
<STRING_STATE>\\t   { buf[buf_index++] = '\t'; }
<STRING_STATE>\\\"  { buf[buf_index++] = '\"'; }
<STRING_STATE>\"    {
                        /* Null-terminate string */
                        buf[buf_index] = '\0';
                        /* Restore initial state */
                        BEGIN 0;
                        #ifdef DEBUG
                        print_debug("Found string '%s'", buf);
                        #endif
                        yylval.strval = strdup(buf);
                        return STRING;
                    }
<STRING_STATE>\n    {
                        buf[buf_index] = '\0';
                        print_error("String not terminated: '%s'", buf);
                        exit(1);
                    }
<STRING_STATE>.     {
                        buf[buf_index++] = *yytext;
                    }
    /* =========================================== */
    /* ================ Operators ================ */
[-+/*()=\n]     {
                    return *yytext;
                }
    /* =========================================== */
    /* ============= Ignore whitespace =========== */
[ \t]           ;
    /* =========================================== */
    /* ====== Throw error for anything else ====== */
.           {
                print_error("Invalid character %s", yytext);
            }
    /* =========================================== */
%%
    /* ================ END RULES ================ */

    /* ================ SUBROUTINES ============== */
int yywrap(void) {
    return 1;
}
    /* ============= END SUBROUTINES ============= */
