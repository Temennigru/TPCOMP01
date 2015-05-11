CC := gcc
LEX := flex
RM := rm -rf
OS := $(shell uname -s)
TARGET := tpcomp01
LEX_SOURCES := cool.flex
C_SOURCES := 
AUTO_C = $(LEX_SOURCES:.flex=.c)
AUTO_H = $(LEX_SOURCES:.flex=-parse.h)
OBJECTS = $(AUTO_C:.c=.o) $(C_SOURCES:.c=.o)
LFLAGS := 

.PHONY: clean

$(TARGET): $(OBJECTS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<

$(OBJECTS): %.o : %.c
	$(CC) $(CFLAGS) -c -o $@ $^

$(AUTO_C): $(AUTO_H)

$(AUTO_C): %.c : %.flex
	$(LEX) $(LFLAGS) -o $@ $^

$(AUTO_H): %-parse.h : %.flex
	$(LEX) $(LFLAGS) --header-file=$@ -o $(@:-parse.h=.c) $^

clean:
	$(RM) $(OBJECTS) $(AUTO_C) $(TARGET)