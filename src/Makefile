DEBUG=-DDEBUG -g
WARNINGS_QUIET=-Wall -Wno-unused-variable -Wno-unused-function
WARNINGS_ALL=-Wall
WARNINGS=$(WARNINGS_QUIET)
C_FILES=lex.yy.c lang.tab.c utils.c
LIBS=-lm
all:
	bison -d lang.y
	flex lang.lex
	gcc $(DEBUG) $(WARNINGS) $(C_FILES) -o lang $(LIBS)
	@make clean
clean:
	@rm lang.tab.*
	@rm lex.yy.c
valgrind: all
	valgrind --leak-check=full --track-origins=yes ./lang
