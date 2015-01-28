DEBUG=-DDEBUG -g
WARNINGS_QUIET=-Wall -Wno-unused-variable -Wno-unused-function
WARNINGS_ALL=-Wall
WARNINGS=$(WARNINGS_QUIET)
C_FILES=lex.yy.c lang.tab.c utils.c hash.c
LIBS=-lm -lreadline
all:
	@bison -d lang.y
	@flex lang.lex
	@mkdir -p ../bin
	@gcc $(DEBUG) $(WARNINGS) $(C_FILES) -o ../bin/lang $(LIBS)
	@make clean
clean:
	@rm -f lang.tab.c lang.tab.h
	@rm -f lex.yy.c
valgrind: all
	valgrind --leak-check=full --track-origins=yes --show-leak-kinds=all --track-fds=yes ../bin/lang
run: all
	../bin/lang
tests: all
	../bin/lang ../tests/tests.gcz
