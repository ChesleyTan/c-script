DEBUG="-DDEBUG"
all:
	bison -d lang.y
	flex lang.lex
	gcc $(DEBUG) lex.yy.c lang.tab.c -o bin/lang
	@make clean
clean:
	@rm lang.tab.*
	@rm lex.yy.c
