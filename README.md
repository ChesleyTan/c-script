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
* Get element at index `"HelloWorld!"[-1]`
* Substring/Reversing `"Reverse this"[-1:0:1]`
* Find substring `"Mary had a little lamb"["had"]`
* Slicing `"Slice this"[::2]`
* Concatenation `"Hello" + " World`
* Subtraction (remove substring) `"Mary had a little lamb" - "little "`
* Multiplication `"Tro" + 1000 * "lo"`
* String division (split on letter) `"I'd just like to interject for a moment." / "interject"`
* Integer to string coercion `1 + "33" + 7`
* String length `#(100 * "a")`

####Integer Arrays
* Array get element at index `arr[index]`
* Array-array concatenation `{1, 2, 3} + {4, 5, 6}`
* Array-element concatenation `{1, 2, 3} + 4 + 5 + 6`
* Array-element subtraction `{1, 2, 3} - 3 - 2 - 1`
* Array multiplication `{1, 2, 3} * 100`
* Array length `#({1, 2, 3} * 100)`

####String Arrays
* Array get element at index `{"Hello", "World"}[1]`
* Array-element concatenation `{"Welcome", "To", "My"} + "Home" + "Stranger"`
* Array length `#{"Hello", "World!"}`
* Result of string division `#"Mary had a little lamb" / "little"`

####Integer arithmetic with order of operations
* Modulus operation `15 % 7`
* Exponent operation `15 ** 7`
* Bitwise operations: `^, |, <<, >>`

####Floating point arithmetic with order of operations
* Modulus operation `3.14159 % 1.4142`
* Exponent operation `3.14159 ** 0.5`

####Boolean operations
* Number Comparison: `>, >=, <, <=, ==, !=`
* Boolean comparison: `&&, ||`
* String Comparison: `>, >=, <, <=, ==, !=`

####Variables
* Storing integer values in variables `thisIsAVariable = 9`

##

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
