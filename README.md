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
1. Make sure you have the Bison Parser Generator and the Flex Lexical Analyzer installed on your computer  
2. Install the GNU Readline Library  
3. Run `$ make`  

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
* Array get element at index `{1, 3, 4}[2]`
* Array-element concatenation `{1, 2, 3} + 4 + 5 + 6`
* Array-element subtraction `{1, 2, 3} - 3 - 2 - 1`
* Array-array concatenation `{1, 2, 3} + {4, 5, 6}`
* Array multiplication `{1, 2, 3} * 100`
* Array length `#({1, 2, 3} * 100)`

####String Arrays
* Array get element at index `{"Hello", "World"}[1]`
* Array-element concatenation `{"Welcome", "To", "My"} + "Home" + "Stranger"`
* Array-array concatenation `{"World"} + {"All", "Cow", "Data", "Oink"} + "Pig"`
* Array multiplication `3 * {"hello"} + "world"`
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
* Storing string values in variables `thisIsAVariable = "Tro" + 100 * "lo"`

##File List
src/lang.lex  
src/lang.y  
src/utils.c  
src/utils.h  
src/hash.c  
src/hash.h  
src/Makefile  
tests/tests.gcz  
LICENSE  
README.md  
TODO.md  
