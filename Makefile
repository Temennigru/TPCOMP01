CC := gcc
LEX := flex
RM := rm -rf
OS := $(shell uname -s)
TARGET := cool_lex
LEX_SOURCES := cool.lex
C_SOURCES := 
AUTO_C = $(LEX_SOURCES:.lex=.c)
OBJECTS = $(AUTO_C:.c=.o) $(C_SOURCES:.c=.o)

.PHONY: clean

$(TARGET): $(OBJECTS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<

$(OBJECTS): %.o : %.c
	$(CC) $(CFLAGS) -c -o $@ $^

$(AUTO_C): %.c : %.lex
	$(LEX) $(LFLAGS) -o $@ $^

clean:
	$(RM) $(OBJECTS) $(AUTO_C) $(TARGET)