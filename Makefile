all:
	yacc -d parser.y
	lex lexer.l
	gcc -g -l fl -l m y.tab.c mc.c
