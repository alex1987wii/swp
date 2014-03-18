# CC=clang
# CC=gcc
# CFLAGS=-I/usr/include -Iinclude -DHAVE_CURSES_H
# LDFLAGS=-lncurses -llua
# LDFLAGS=-lncurses -llua5.1 -I/usr/include/lua5.1

CLIBS= -lncurses 
CC=/opt/ad6900/arm-compiler/bin/arm-linux-gcc
CFLAGS=-I/opt/ad6900/arm-compiler/arm-none-linux-gnueabi/include/ncurses -Iinclude -DHAVE_NCURSES_CURSES_H
UNILIB_PATH= /home/simba/src/ad6900/unilibs
DSP_INC= -I$(UNILIB_PATH)/libbitdsp -L$(UNILIB_PATH)/libbitdsp -L/$(UNILIB_PATH)/dspadapter -L/$(UNILIB_PATH)/timers -L$(UNILIB_PATH)/annal -L$(UNILIB_PATH)/circbuf -L$(UNILIB_PATH)/crc16
NONDSP_INC= -I/home/simba/src/ad6900/unilibs/libbitnondsp/include

all: lib/curses_c.so lib/posix_c.so lib/bit32.so lib/lnondsp.so

lib/curses_c.so: curses/curses.c
	$(CC) -Wall -shared -o $@ -fPIC $^ $(CFLAGS) $(CLIBS)

lib/posix_c.so: posix/posix.c
	$(CC) -Wall -shared -o $@ -fPIC $^ $(CFLAGS) $(CLIBS) -lrt -lcrypt
	
lib/bit32.so: bit32/bit32.c
	$(CC) -Wall -shared -o $@ -fPIC $^ $(CFLAGS)
	
lib/ldsp.so: ldsp/ldsp.c
	$(CC) -Wall -shared -o $@ -fPIC $^ $(CFLAGS) -ldspadapter -lbitdsp -lpthread -ltimers -lannal -lcircbuf -lcrc16 $(DSP_INC)
	
lib/lnondsp.so: lnondsp/lnondsp.c
	$(CC) -Wall -shared -o $@ -fPIC $^ $(CFLAGS) -lbitnondsp $(NONDSP_INC)

clean:
	rm -rf lib/curses_c.so lib/posix_c.so lib/bit32.so
