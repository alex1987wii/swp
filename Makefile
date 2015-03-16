# CC=clang
# CC=gcc
# CFLAGS=-I/usr/include -Iinclude -DHAVE_CURSES_H
# LDFLAGS=-lncurses -llua
# LDFLAGS=-lncurses -llua5.1 -I/usr/include/lua5.1

PROJECT=CONFIG_PROJECT_G4_BBA
# PROJECT=CONFIG_PROJECT_U3_2ND

CLIBS= -lncurses 
CC=/opt/ad6900/arm-compiler/bin/arm-linux-gcc
CFLAGS=-I/opt/ad6900/arm-compiler/arm-none-linux-gnueabi/include/ncurses -Iinclude -DHAVE_NCURSES_CURSES_H
AD6900_PATH= /home/simba/worksrc/ad6900
UNILIB_PATH= $(AD6900_PATH)/unilibs
ROOTFS_IFS_PATH= $(AD6900_PATH)/output/ifs/rootfs
DSP_INC= -I$(UNILIB_PATH)/libbitdsp -L$(UNILIB_PATH)/caldb -L$(UNILIB_PATH)/libbitdsp -I/$(UNILIB_PATH)/dspadapter/include -L/$(UNILIB_PATH)/dspadapter -L/$(UNILIB_PATH)/timers -L$(UNILIB_PATH)/annal -L$(UNILIB_PATH)/circbuf -L$(UNILIB_PATH)/crc16 -L$(ROOTFS_IFS_PATH)/lib
# NONDSP_INC= -I$(UNILIB_PATH)/libbitnondsp/include -L$(UNILIB_PATH)/libbitnondsp -L/$(UNILIB_PATH)/timers -L$(UNILIB_PATH)/annal -L$(UNILIB_PATH)/circbuf -I$(UNILIB_PATH)/bitservice/include
NONDSP_INC= -I$(UNILIB_PATH)/libbitnondsp/include -I$(UNILIB_PATH)/libbitnondsp/nondspdriver -I$(UNILIB_PATH)/gps/include -L$(ROOTFS_IFS_PATH)/lib -I$(UNILIB_PATH)/bitservice/include -L$(UNILIB_PATH)/bt 

ifeq (CONFIG_PROJECT_G4_BBA, $(PROJECT))
DSP_INC += -lcaldb 
endif

all: lib/curses_c.so lib/posix_c.so lib/bit32.so lib/ldsp.so lib/lnondsp.so

lib/curses_c.so: curses/curses.c
	$(CC) -Wall -shared -o $@ -fPIC $^ $(CFLAGS) $(CLIBS)

lib/posix_c.so: posix/posix.c
	$(CC) -Wall -shared -o $@ -fPIC $^ $(CFLAGS) $(CLIBS) -lrt -lcrypt
	
lib/bit32.so: bit32/bit32.c
	$(CC) -Wall -shared -o $@ -fPIC $^ $(CFLAGS)
	
lib/ldsp.so: ldsp/ldsp.c
	$(CC) -Wall -shared -o $@ -fPIC $^ $(CFLAGS) -ldspadapter -lbitdsp -lpthread -ltimers -lannal -lcircbuf -lcrc16 $(DSP_INC) -D$(PROJECT)
	
lib/lnondsp.so: lnondsp/lnondsp.c
	$(CC) -Wall -shared -o $@ -fPIC $^ $(CFLAGS) $(NONDSP_INC) -D$(PROJECT) -lbitnondsp -lpthread -ltimers -lannal -lcircbuf -lbluetooth -ldspadapter -lbitdsp -lcrc16 

install:
	cp lib/*.so front_panel/arm-so
clean:
	rm -rf lib/curses_c.so lib/posix_c.so lib/bit32.so lib/ldsp.so lib/lnondsp.so
