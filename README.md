C-Script
============
#A scripting language written using Bison and Flex, and including a built-in REPL
## Authors
[Genji Noguchi] (https://github.com/genjinoguchi)  
[Chesley Tan] (https://github.com/ChesleyTan)  
[Daniel Zabari] (https://github.com/Zabari)  
## About
This project was written as a final project for the Fall 2014 Systems Level Programming class (4th period) at Stuyvesant High School
##Building the Project
1. Install the GNU Readline Library  
2. Run `$ make`  

##Running the Project
1. Run `$ ./lang <file>` or alternatively `$ ./lang` for an interactive shell  

##Features
####REPL with navigation and command history
####String operations
* Get element at index
* Substring/Reversing
* Find substring
* Slicing
* Concatenation
* Subtraction (remove substring)
* Multiplication
* String division (split on token)
* Integer to string coercion
* String length

####Integer Arrays
* Array get element at index
* Array-array concatenation
* Array-element concatenation
* Array-element subtraction
* Array multiplication
* Array length

####String Arrays
* Array get element at index
* Array length
* Result of string division

####Integer arithmetic with order of operations
* Modulus operation
* Exponent operation
* Bitwise operations: `^, |, <<, >>`

####Floating point arithmetic with order of operations
* Modulus operation
* Exponent operation

####Boolean operations
* Number Comparison: `>, >=, <, <=, ==, !=`
* Boolean comparison: `&&, ||`
* String Comparison: `>, >=, <, <=, ==, !=`

####Variables
* Storing integer values in variables

##File List
src/lang.lex  
src/lang.y  
src/utils.c  
src/utils.h  
src/hash.c  
src/hash.h  
src/Makefile  
LICENSE  
README.md  
TODO.md  
