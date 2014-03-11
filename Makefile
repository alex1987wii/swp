# CC=clang
CC=gcc
CFLAGS=-I/usr/include -Iinclude -DHAVE_CURSES_H
# LDFLAGS=-lncurses -llua
# LDFLAGS=-lncurses -llua5.1 -I/usr/include/lua5.1

CLIBS= -lncurses 
# CC=/opt/ad6900/arm-compiler/bin/arm-linux-gcc
# CFLAGS=-I/opt/ad6900/arm-compiler/arm-none-linux-gnueabi/include/ncurses -Iinclude -DHAVE_NCURSES_CURSES_H

all: lib/curses_c.so lib/posix_c.so lib/bit32.so

lib/curses_c.so: curses/curses.c
	$(CC) -Wall -shared -o $@ -fPIC $^ $(CFLAGS) $(CLIBS)

lib/posix_c.so: posix/posix.c
	$(CC) -Wall -shared -o $@ -fPIC $^ $(CFLAGS) $(CLIBS) -lrt -lcrypt
	
lib/bit32.so: bit32/bit32.c
	$(CC) -Wall -shared -o $@ -fPIC $^ $(CFLAGS)

clean:
	rm -rf lib/curses_c.so lib/posix_c.so lib/bit32.so
