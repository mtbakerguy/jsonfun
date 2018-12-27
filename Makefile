YFLAGS=-d
CC=c++
CFLAGS=-g -I. -O2
LDLIBS=-ll
EXE=jsonparse

all: $(EXE)

jsonparse: y.tab.o lex.yy.o
	$(CC) -o jsonparse y.tab.o lex.yy.o -ll

test: jsonparse
	./jsonparse < t
	$(CC) -g -I. -O2 -o weaktest weaktest.cpp  lex.yy.o y.tab.o
	./weaktest < t

lex.yy.o: json.l y.tab.c

lex.yy.c: json.l y.tab.c JSON.h
	$(LEX) -f json.l

y.tab.o: y.tab.c

y.tab.c: json.y JSON.h
	$(YACC) $(YFLAGS) json.y

clean:
	rm -f weaktest jsonparse lex.yy.c y.tab.c y.tab.h *.o
