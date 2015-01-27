A scripting language written using Bison and Flex including a built-in REPL
============
#Building the Project
1. Install the GNU Readline Library  
2. Run `$ make`  

#Running the Project
1. Run `./lang <file>` or alternatively `./lang` for an interactive shell  

#Features
##REPL with navigation and command history
##String operations
* Get element at index
* Substring
* Find substring
* Reversing
* Slicing
* Concatenation
* Subtraction
* Multiplication
* Integer to string coercion

##String length
* Integer arithmetic with order of operations
* Modulus operation
* Exponent operation
* Bitwise operations: `^, |, <<, >>`

##Floating point arithmetic with order of operations
* Modulus operation
* Exponent operation

##Boolean operations
* Number Comparison: `>, >=, <, <=, ==, !=`
* Boolean comparison: `&&, ||`
* String Comparison: `>, >=, <, <=, ==, !=`

#File List
src/lang.lex  
src/lang.y  
src/utils.c  
src/utils.h  
src/Makefile  
