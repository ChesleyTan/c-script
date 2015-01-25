DEBUG="-DDEBUG -g"
WARNINGS_QUIET=-Wall -Wno-unused-variable -Wno-unused-function
WARNINGS_ALL=-Wall
WARNINGS=$(WARNINGS_QUIET)
all:
	bison -d lang.y
	flex lang.lex
	gcc $(DEBUG) $(WARNINGS) lex.yy.c lang.tab.c -o lang
	@make clean
clean:
	@rm lang.tab.*
	@rm lex.yy.c
valgrind: all
	valgrind --leak-check=full --track-origins=yes ./lang
