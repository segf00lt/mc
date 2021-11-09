CC = gcc
CFLAGS = -pedantic -Wall
LIBS = -l fl -l m
SRC = y.tab.c lex.yy.c mc.c
PARSEGEN = yacc -d
LEXGEN = flex -X --header-file=lex.yy.h

all:
	${PARSEGEN} parser.y
	${LEXGEN} lexer.l
	${CC} ${CFLAGS} ${LIBS} ${SRC} -o mc

debug:
	${PARSEGEN} parser.y
	${LEXGEN} lexer.l
	${CC} -g ${CFLAGS} ${LIBS} ${SRC} -o debug

clean:
	rm -f lex.yy.c lex.yy.h y.tab.c y.tab.h debug mc
