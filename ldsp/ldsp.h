/*

*/
#ifndef LDSP_H
#define LDSP_H

#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <sys/stat.h>

#include <unistd.h>
#include <fcntl.h>
#include <utime.h>
#include <sys/statfs.h>

#include <sys/mman.h>
#include <stdint.h>

#include <linux/ioctl.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include <libbitdsp.h>
#include <dsp_init.h>

#define TRUE  1
#define FALSE 0

#define LUA_LDSP_LIBNAME "ldsp"
LUALIB_API int luaopen_ldsp(lua_State *L);

#define lua_pushinteger2table(L,key,val) do{\
	lua_pushstring(L, key);\
	lua_pushinteger(L, val);\
	lua_settable(L, -3);\
}while(0)

#define lua_pushintegerkey2table(L,key,val) do{\
	lua_pushinteger(L, key);\
	lua_pushinteger(L, val);\
	lua_settable(L, -3);\
}while(0)

#define lua_pushstring2table(L,key,val) do{\
	lua_pushstring(L, key);\
	lua_pushstring(L, val);\
	lua_settable(L, -3);\
}while(0)

#define lua_pushboolean2table(L,key,val) do{\
	lua_pushstring(L, key);\
	lua_pushboolean(L, val);\
	lua_settable(L, -3);\
}while(0)

#define lua_pushlightuserdata2table(L,key,val) do{\
	lua_pushstring(L, key);\
	lua_pushlightuserdata(L, (void *)val);\
	lua_settable(L, -3);\
}while(0)

#define lua_pushnil2table(L,key) do{\
	lua_pushstring(L, key);\
	lua_pushnil(L);\
	lua_settable(L, -3);\
}while(0)

#endif 
