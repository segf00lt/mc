VERSION = 0.1
CC = gcc
CFLAGS = -pedantic -Wall
LIBS = -l fl -l m
SRC = y.tab.c lex.yy.c mc.c
PARSEGEN = yacc -d
LEXGEN = flex -X --header-file=lex.yy.h

PREFIX = /usr/local
MANPREFIX = ${PREFIX}/share/man

all:
	${PARSEGEN} parser.y
	${LEXGEN} lexer.l
	${CC} ${CFLAGS} ${LIBS} ${SRC} -o mc

debug:
	${PARSEGEN} -Wother -Wconflicts-rr -Wcounterexamples parser.y
	${LEXGEN} lexer.l
	${CC} -g ${CFLAGS} ${LIBS} ${SRC} -o debug

install: all
	mkdir -p ${PREFIX}/bin
	cp -f mc ${PREFIX}/bin
	chmod 755 ${PREFIX}/bin/mc
	mkdir -p ${MANPREFIX}/man1
	sed "s/VERSION/${VERSION}/g" < mc.1 > ${MANPREFIX}/man1/mc.1
	chmod 644 ${MANPREFIX}/man1/mc.1

uninstall:
	rm -f ${PREFIX}/bin/mc ${MANPREFIX}/man1/mc.1

clean:
	rm -f lex.yy.c lex.yy.h y.tab.c y.tab.h debug mc
