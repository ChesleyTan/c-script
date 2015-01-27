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
    int int_buf_resize(size_t);
    size_t buf_size = 0;
    size_t buf_index = 0;
    char *buf;
    size_t int_buf_size = 0;
    size_t int_buf_index = 0;
    /* 
     * NOTE: int arrays are delimited with their size (inclusive of the 0 index)
     * at index 0 
     */
    int *int_buf;
%}

    /* Parse state for control flow */
%x CONTROL_STATE
    /* Parse state for strings */
%x STRING_STATE 
    /* Parse state for comments */
%x COMMENT
    /* Parse state for integer arrays */
%x INT_ARRAY_STATE

INTEGER             (-)?[0-9]+
BOOLEAN		    true|false
WHITESPACE          [ \t]
    /* ============= END DEFINITIONS ============= */

    /* ================== RULES ================== */
%%
    /*================ Control Flow ===============*/
"=="		return EQUALS;
"if"		return IF;
"else"		return ELSE;
    /* ============================================*/
    /* ================ Variables ================ */
[a-z]           {

    yylval.intval = *yytext - 'a';
    return VARIABLE;

                }
    /* =========================================== */
    /* ================ Booleans ================= */
{BOOLEAN}		{

	#ifdef DEBUG
	print_debug("Found boolean: %s", yytext);
	#endif
	if( strcmp(yytext, "true") == 0 ) {
		yylval.boolval = 1;
	} else {
		yylval.boolval = 0;
	}
	return BOOLEAN;

				}
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
\"              { BEGIN(STRING_STATE); buf_index = 0; }
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
        /* Restore initial state */
        BEGIN(INITIAL);
        #ifdef DEBUG
        print_debug("Found string '%s'", buf);
        #endif
        yylval.strval = strdup(buf);
        buf_index = 0;
        return STRING;
    }

                    }
<STRING_STATE>\n    {

    if (buf_resize(0) != -1) {
        /* Null-terminate string */
        buf[buf_index] = '\0';
        print_error("String not terminated: '%s'", buf);
        /* Restore initial state */
        BEGIN(INITIAL);
    }

                    }
<STRING_STATE>.     {

    if (buf_resize(1) != -1) {
        buf[buf_index++] = *yytext;
    }

                    }
    /* =========================================== */
    /* ================== Arrays ================= */
"\["{WHITESPACE}*{INTEGER}   {

    if (int_buf_resize(0) != -1) {
        int_buf_index = 1;
        #ifdef DEBUG
        print_debug("Found int array start: %s", yytext);
        #endif
        BEGIN(INT_ARRAY_STATE);
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
<INT_ARRAY_STATE>"]"    {

    if (int_buf_resize(0) != -1) {
        #ifdef DEBUG
        print_debug("Found int array end: %s", yytext);
        #endif
        BEGIN(INITIAL);
        /* Put array size at 0 index of int_buf */
        int_buf[0] = int_buf_index;
        yylval.int_arrayval = intdup(int_buf, int_buf_index);
        int_buf_index = 0;
        return INT_ARRAY;
    }

                        }
<INT_ARRAY_STATE>,[ ]?          ;
<INT_ARRAY_STATE>{WHITESPACE}   ;
    /* =========================================== */
    /* ================ Operators ================ */
[-+/*%()=\n^<>|\[\]:#]  { return *yytext; }
    /* =========================================== */
    /* ============= Ignore comments ============= */
"/*"                            { BEGIN(COMMENT); }
    /* Non-greedy regex */
<COMMENT>(("*"[^/])?|[^*])*     ;
<COMMENT>"*/"                   { BEGIN(INITIAL); }
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
    /* ============= END SUBROUTINES ============= */
