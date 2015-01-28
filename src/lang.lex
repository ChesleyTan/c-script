    /* =============== DEFINITIONS ============= */
%option stack
%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <sys/types.h>

    #include "utils.h"
    #include "hash.h"
    #include "lang.tab.h"

    #define ERRMSG_LENGTH 100

    void yyerror(char *);
    extern hash_table *sym;

    int buf_resize(size_t);
    int int_buf_resize(size_t);
    int str_buf_resize(size_t);
    void restore_initial_state();
    char *buf;
    size_t buf_size = 0;
    size_t buf_index = 0;
    char buf_ready = 0;
    /*
     * NOTE: int arrays are delimited with their size (inclusive of the 0 index)
     * at index 0
     */
    int *int_buf;
    size_t int_buf_size = 0;
    size_t int_buf_index = 0;
    /*
     * NOTE: string arrays are delimited with a trailing null
     */
    char **str_buf;
    size_t str_buf_size = 0;
    size_t str_buf_index = 0;

%}

    /* Parse state for control flow */
%x CONTROL_STATE
    /* Parse state for strings */
%x STRING_STATE
    /* Parse state for comments */
%x COMMENT
    /* Parse state for integer arrays */
%x INT_ARRAY_STATE
    /* Parse state for string arrays */
%x STRING_ARRAY_STATE

INTEGER             (-)?[0-9]+
WHITESPACE          [ \t]
    /* ============= END DEFINITIONS ============= */

    /* ================== RULES ================== */
%%
    /*================ Control Flow ===============*/
"if"        return IF;
"endif"     return ENDIF;
"else"      return ELSE;
"while"     return WHILE;
    /* ============================================*/
    /* ================ Comparators ===============*/
[^>]">"[^>=]    return GT;
[^<]"<"[^<=]    return LT;
">="            return GTE;
"<="            return LTE;
"=="            return EQL;
"!="            return NEQ;
"&&"            return AND;
"||"            return OR;
    /* ============================================*/
    /* ================ Booleans ==================*/

(true|false)        {
    #ifdef DEBUG
    print_debug("Found boolean: %s", yytext );
    #endif
    if (strcmp( yytext, "true") == 0) {
        yylval.boolval = 1;
    }
    else {
        yylval.boolval = 0;
    }
    return BOOLEAN;

                    }
    /* ============================================*/
    /* ================ Integers ================= */
{INTEGER}      {

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
<INITIAL,STRING_ARRAY_STATE>\"          {

    yy_push_state(STRING_STATE);
    buf_index = 0;
    buf_ready = 0;

                                        }
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

    if (buf_resize(0) != -1) {
        /* Null-terminate string */
        buf[buf_index] = '\0';
        #ifdef DEBUG
        print_debug("Found string '%s'", buf);
        #endif
        buf_index = 0;
        int previous_state = yy_top_state();
        /* Restore initial state */
        yy_pop_state();
        if (previous_state != STRING_ARRAY_STATE) {
            yylval.strval = strdup(buf);
            buf_ready = 0;
            return STRING;
        }
        else {
            buf_ready = 1;
        }
    }

                    }
<STRING_STATE>\n    {

    if (buf_resize(0) != -1) {
        /* Null-terminate string */
        buf[buf_index] = '\0';
        print_error("String not terminated: '%s'", buf);
        YY_FLUSH_BUFFER;
        /* Restore initial state */
        restore_initial_state();
        /* Reset string buffer */
        buf_ready = 0;
    }

                    }
<STRING_STATE>.     {

    if (buf_resize(1) != -1) {
        buf[buf_index++] = *yytext;
    }

                    }
    /* =========================================== */
    /* ============== Integer Arrays ============= */
"\{"{WHITESPACE}*{INTEGER}   {

    if (int_buf_resize(0) != -1) {
        int_buf_index = 1;
        #ifdef DEBUG
        print_debug("Found int array start: %s", yytext);
        #endif
        yy_push_state(INT_ARRAY_STATE);
        #ifdef DEBUG
        print_debug("Found int array element: %d",
            atoi(yytext + 1));
        #endif
        int_buf[int_buf_index++] = atoi(yytext + 1);
    }

                            }
<INT_ARRAY_STATE>{INTEGER}  {

    if (int_buf_resize(1) != -1) {
        #ifdef DEBUG
        print_debug("Found int array element: %d",
            atoi(yytext));
        #endif
        int_buf[int_buf_index++] = atoi(yytext);
    }

                            }
<INT_ARRAY_STATE>"}"    {

    if (int_buf_resize(0) != -1) {
        #ifdef DEBUG
        print_debug("Found int array end: %s", yytext);
        #endif
        yy_pop_state();
        /* Put array size at 0 index of int_buf */
        int_buf[0] = int_buf_index;
        yylval.int_arrayval = intdup(int_buf, int_buf_index);
        int_buf_index = 0;
        return INT_ARRAY;
    }

                        }
<INT_ARRAY_STATE>\n     {

        print_error("Integer array not terminated.");
        /* Restore initial state */
        restore_initial_state();

                        }
<INT_ARRAY_STATE>,[ ]?          ;
<INT_ARRAY_STATE>{WHITESPACE}   ;
<INT_ARRAY_STATE>.              ;
    /* =========================================== */
    /* ============== String Arrays ============== */
"\{"                        {

    #ifdef DEBUG
    print_debug("Found string array start: %s", yytext);
    #endif
    yy_push_state(STRING_ARRAY_STATE);
    str_buf_index = 0;

                            }
<STRING_ARRAY_STATE>"\}"    {

    if (str_buf_resize(1) != -1) {
        #ifdef DEBUG
        print_debug("Found string array end: %s", yytext);
        if (buf_ready) {
            print_debug("Found string array element '%s'", buf);
        }
        #endif
        if (buf_ready) {
            char *s = strdup(buf);
            str_buf[str_buf_index++] = s;
            buf_ready = 0;
        }
        str_buf[str_buf_index] = NULL;
        yylval.str_arrayval = str_arrdup(str_buf, str_buf_index + 1);
        str_buf_index = 0;
        yy_pop_state();
        return STRING_ARRAY;
    }
    yy_pop_state();

                            }
<STRING_ARRAY_STATE>\n      {

        print_error("String array not terminated.");
        YY_FLUSH_BUFFER;
        /* Restore initial state */
        restore_initial_state();
        /* Reset string buffer */
        buf_ready = 0;

                            }
<STRING_ARRAY_STATE>,[ ]?   {

    if (str_buf_resize(1) != -1) {
        #ifdef DEBUG
        if (buf_ready) {
            print_debug("Found string array element '%s'", buf);
        }
        #endif
        if (buf_ready) {
            char *s = strdup(buf);
            str_buf[str_buf_index++] = s;
            buf_ready = 0;
        }
    }

                            }
<STRING_ARRAY_STATE>{WHITESPACE}    ;
<STRING_ARRAY_STATE>.               ;
    /* =========================================== */
    /* ================ Operators ================ */
[-+/*%()=\n^<>|\[\]:#]  { return *yytext; }
    /* =========================================== */
    /* ============= Ignore comments ============= */
"/*"                            { yy_push_state(COMMENT); }
    /* Non-greedy regex */
<COMMENT>(("*"[^/])?|[^*])*     ;
<COMMENT>"*/"                   { yy_pop_state(); }
    /* =========================================== */
    /* ================ Variables ================ */
[A-Za-z]+          {

    yylval.varval = strdup(yytext);
    #ifdef DEBUG
    print_debug("Got variable: %s", yytext);
    #endif
    linked_list *res = lookup(sym, yytext);
    #ifdef DEBUG
    if (res != NULL) {
        print_debug("Got variable recall: %s", yytext);
    }
    #endif
    if (res != NULL) {
        switch (res->type) {
            case INTEGER_VALUE:
                return INT_VARIABLE;
            case STRING_VALUE:
                return STR_VARIABLE;
            default:
                return INT_VARIABLE;
        }
    }
    else {
        return VARIABLE;
    }

                }
    /* =========================================== */
    /* ============= Ignore whitespace =========== */
{WHITESPACE}           ;
    /* =========================================== */
    /* ====== Throw error for anything else ====== */
.           { print_error("Invalid character %s", yytext); }
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
        if ((new_ptr = realloc(buf, sizeof(char) * buf_size))) {
            buf = new_ptr;
        }
        else {
            return -1;
        }
    }
    return 0;
}
int int_buf_resize(size_t size_change) {
    /*
        Resizes the buffer if necessary
        Returns 0 on success; -1 on failure
    */
    if (int_buf_size == 0) {
        if ((int_buf = (int *) malloc(2 * sizeof(int)))) {
            int_buf_size = 2;
        }
    }
    else if (int_buf_index + size_change > int_buf_size - 1) {
        int_buf_size *= 2;
        #ifdef DEBUG
        print_debug("Integer buffer resized to %d", int_buf_size);
        #endif
        int *new_ptr;
        if ((new_ptr = realloc(int_buf, sizeof(int) * int_buf_size))) {
            int_buf = new_ptr;
        }
        else {
            return -1;
        }
    }
    return 0;
}
int str_buf_resize(size_t size_change) {
    /*
        Resizes the buffer if necessary
        Returns 0 on success; -1 on failure
    */
    if (str_buf_size == 0) {
        if ((str_buf = (char **) malloc(2 * sizeof(char *)))) {
            str_buf_size = 2;
        }
    }
    else if (str_buf_index + size_change > str_buf_size - 1) {
        str_buf_size *= 2;
        #ifdef DEBUG
        print_debug("String array buffer resized to %d", str_buf_size);
        #endif
        char **new_ptr;
        if ((new_ptr = realloc(str_buf, sizeof(char *) * str_buf_size))) {
            str_buf = new_ptr;
        }
        else {
            return -1;
        }
    }
    return 0;
}
void restore_initial_state() {
    while (yy_top_state() != INITIAL) {
        yy_pop_state();
    }
    yy_pop_state();
}
    /* ============= END SUBROUTINES ============= */
