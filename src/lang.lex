    /* =============== DEFINITIONS ============= */
%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <sys/types.h>

    #include "utils.h"
    #include "lang.tab.h"

    #define ERRMSG_LENGTH 100

    void yyerror(char *);
    int buf_resize(size_t);
    size_t buf_size = 0;
    size_t buf_index = 0;
    char *buf;
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
(-)?[0-9]+      {
                    yylval.intval = atoi(yytext);
                    #ifdef DEBUG
                    print_debug("Found integer: %d", yylval.intval);
                    #endif
                    return INTEGER;
                }
    /* =========================================== */
    /* ================= Floats ================== */
(-)?([0-9]+(\.)[0-9]*|[0-9]*(\.)[0-9]+)     {
                                                yylval.floatval = atof(yytext);
                                                #ifdef DEBUG
                                                print_debug("Found float: %f",
                                                            yylval.floatval);
                                                #endif
                                                return FLOAT;
                                            }
    /* =========================================== */
    /* ================= Strings ================= */
\"              { BEGIN STRING_STATE; buf_index = 0; }
<STRING_STATE>\\n   {
                        if (buf_resize(1) != -1) {
                            buf[buf_index++] = '\n';
                        }
                    }
<STRING_STATE>\\t   {
                        if (buf_resize(1) != -1) {
                            buf[buf_index++] = '\t';
                        }
                    }
<STRING_STATE>\\\"  {
                        if (buf_resize(1) != -1) {
                            buf[buf_index++] = '\"';
                        }
                    }
<STRING_STATE>\"    {
                        /* Null-terminate string */
                        buf[buf_index] = '\0';
                        /* Restore initial state */
                        BEGIN 0;
                        #ifdef DEBUG
                        print_debug("Found string '%s'", buf);
                        #endif
                        yylval.strval = strdup(buf);
                        buf_index = 0;
                        return STRING;
                    }
<STRING_STATE>\n    {
                        /* Null-terminate string */
                        buf[buf_index] = '\0';
                        print_error("String not terminated: '%s'", buf);
                        exit(1);
                    }
<STRING_STATE>.     {
                        if (buf_resize(1) != -1) {
                            buf[buf_index++] = *yytext;
                        }
                    }
    /* =========================================== */
    /* ================ Operators ================ */
[-+/*%()=\n^<>|]    {
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
int buf_resize(size_t size_change) {
    /*
        Resizes the buffer if necessary
        Returns 0 on success; -1 on failure
    */
    if (buf_size == 0) {
        if ((buf = (char *) malloc(2 * sizeof(char)))) {
            buf_size = 2;
        }
    }
    else if (buf_index + size_change > buf_size - 1) {
        buf_size *= 2;
        #ifdef DEBUG
        print_debug("String buffer resized to %d", buf_size);
        #endif
        char *new_ptr;
        if ((new_ptr = realloc(buf, buf_size))) {
            buf = new_ptr;
        }
        else {
            return -1;
        }
    }
    return 0;
}
    /* ============= END SUBROUTINES ============= */
