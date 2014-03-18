
#include "lnondsp.h"

/* GPS test interface */
static int lnondsp_gps_enable(lua_State *L)
{
    int ret = -1;

    ret = GPSEnable();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

static int lnondsp_gps_disable(lua_State *L)
{
    int ret = -1;

    ret = GPSDisable();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* LCD test interface */
static int lnondsp_lcd_enable(lua_State *L)
{
    int ret = -1;

    ret = enableLcdModule();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

static int lnondsp_lcd_disable(lua_State *L)
{
    int ret = -1;

    ret = disableLcdModule();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

static int lnondsp_lcd_display_static_image(lua_State *L)
{
    const char *pic_path = NULL;
    uint32_t width = 0;
    uint32_t height = 0; 
    
    int ret = -1;
    int argcnt = 0;
    
	argcnt = lua_gettop(L);
	if (argcnt >= 3 && lua_isstring(L, 1)) {
        pic_path = (char *)lua_tostring(L, 1);
        width = (uint32_t)lua_tointeger(L, 2);
        height = (uint32_t)lua_tointeger(L, 3);
    }
    
    ret = lcdDisplayStaticImage(pic_path, width, height);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

static int lnondsp_lcd_slide_show_test_start(lua_State *L)
{
    const char *path = NULL;
    uint8_t path_len = 0;
    uint32_t range = 0; 
    
    int ret = -1;
    int argcnt = 0;
    
	argcnt = lua_gettop(L);
	if (argcnt >= 3 && lua_isstring(L, 1)) {
        path = (char *)lua_tostring(L, 1);
        path_len = strlen(path);
        range = (uint32_t)lua_tointeger(L, 3);
    }
    
    ret = lcdSlideShowTestStart(path, path_len, range);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

static int lnondsp_lcd_slide_show_test_stop(lua_State *L)
{
    int ret = -1;

    ret = lcdSlideShowTestStop();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

static int lnondsp_lcd_pattern_test(lua_State *L)
{
    int ret = -1;

    ret = lcdPatternTest();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

static int lnondsp_lcd_backlight_enable(lua_State *L)
{
    int ret = -1;

    ret = enableLcdBacklight();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

static int lnondsp_lcd_backlight_disable(lua_State *L)
{
    int ret = -1;

    ret = disableLcdBacklight();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* LED test interface */
static int lnondsp_led_config(lua_State *L)
{
    uint8_t ledid;    
    uint32_t period;  
    uint32_t percent; 
    uint32_t cycles; 
    
    int i;
    int ret = -1;
    int argcnt = 0;
    
	argcnt = lua_gettop(L);
	if (argcnt < 4) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -1);
        return 2;
    }
    
    for (i=1; i<=argcnt; i++){
        if (!lua_isnumber(L, i)) {
            lua_pushboolean(L, FALSE);
            lua_pushinteger(L, i);
            return 2;
        }
    }
    
    ledid = (uint8_t)lua_tointeger(L, 1);
    period = (uint32_t)lua_tointeger(L, 2);
    percent = (uint32_t)lua_tointeger(L, 3);
    cycles = (uint32_t)lua_tointeger(L, 4);
    
    ret = configLED(ledid, period, percent, cycles);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

static int lnondsp_led_selftest_start(lua_State *L)
{
    int ret = -1;

    ret = ledSelfTestStart();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

static int lnondsp_led_selftest_stop(lua_State *L)
{
    int ret = -1;

    ret = ledSelfTestStop();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}
/*
 * interface for lua
 */
static const struct luaL_reg nondsp_lib[] = 
{
    {"gps_enable",				lnondsp_gps_enable},
    {"gps_disable",				lnondsp_gps_disable},

    {"lcd_enable",				    lnondsp_lcd_enable},
    {"gps_disable",				    lnondsp_lcd_disable},
    {"lcd_display_static_image",	lnondsp_lcd_display_static_image},
    {"lcd_slide_show_test_start",	lnondsp_lcd_slide_show_test_start},
    {"lcd_slide_show_test_stop",	lnondsp_lcd_slide_show_test_stop},
    {"lcd_pattern_test",				lnondsp_lcd_pattern_test},
    {"lcd_backlight_enable",			lnondsp_lcd_backlight_enable},
    {"lcd_backlight_disable",		lnondsp_lcd_backlight_disable},
    
    {"led_config",				lnondsp_led_config},
    {"led_selftest_start",		lnondsp_led_selftest_start},
    {"led_selftest_stop",		lnondsp_led_selftest_stop},
    {NULL, NULL}
};

int luaopen_lnondsp(lua_State *L) {
	luaL_register (L, LUA_LNONDSP_LIBNAME, nondsp_lib);
	return 1;
}
