
#include "ldsp.h"

static int ldsp_load_image(lua_State *L)
{
    const char *imagepath = NULL;
    int path_len = 0;
    int ret = -1;
    int argcnt = 0;
    
	argcnt = lua_gettop(L);
	if (argcnt >= 1 && lua_isstring(L, 1)) {
        imagepath = (char *)lua_tostring(L, 1);
        path_len = strlen(imagepath);
    }
    
    ret = load_dsp_image(imagepath, path_len);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

static int ldsp_release(lua_State *L)
{
    int ret = -1;

    ret = release_dsp();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

static int ldsp_stop(lua_State *L)
{
    int ret = -1;

    ret = stop_dsp();
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
 * DSP complex function interface 
 */
/* single power measurement interface */
static int ldsp_start_rx_power_measurement(lua_State *L)
{
    unsigned int samples;    
    unsigned int interval;  
    unsigned int records; 
    
    int i;
    int ret = -1;
    int argcnt = 0;
    
	argcnt = lua_gettop(L);
	if (argcnt < 3) {
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
    
    samples = (unsigned int)lua_tointeger(L, 1);
    interval = (unsigned int)lua_tointeger(L, 2);
    records = (unsigned int)lua_tointeger(L, 3);
    
    ret = start_rx_power_measurement(samples, interval, records);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

static int ldsp_get_period_power_msr_data(lua_State *L)
{
    unsigned int start;    
    unsigned int num;  
    unsigned int size; 
    unsigned char *data_buf = NULL;
    
    int i;
    int ret = -1;
    int argcnt = 0;
    
	argcnt = lua_gettop(L);
	if (argcnt < 4) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -1);
        return 2;
    }
    
    for (i=1; i<=3; i++){
        if (!lua_isnumber(L, i)) {
            lua_pushboolean(L, FALSE);
            lua_pushinteger(L, i);
            return 2;
        }
    }
    
    if (!lua_isuserdata(L, 4)) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -4);
        return 2;
    }

    start = (unsigned int)lua_tointeger(L, 1);
    num = (unsigned int)lua_tointeger(L, 2);
    size = (unsigned int)lua_tointeger(L, 3);
    data_buf = (unsigned char *)lua_touserdata(L, 4);
    
    ret = get_period_power_msr_data(start, num, size, data_buf);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* DSP RX desense scan interface */
static int ldsp_start_rx_desense_scan(lua_State *L)
{
    unsigned int freq;    /* Transmit freq, value range in UHF, VHF or WLB */
    unsigned char band_width;  /* 0->12.5KHz, 1->25KHz */
    unsigned int step_size;  /* 0Hz, 12500Hz, 25000Hz, 100000Hz and 1000000Hz */
    unsigned int step_num;   /* 0~ 15000 */
    unsigned int msr_step_num; /* 0~50 */
    unsigned int samples;     /* 10~50000 */
    unsigned int delaytime;   /* 0~100(seconds) */
    
    int i;
    int ret = -1;
    int argcnt = 0;
    
	argcnt = lua_gettop(L);
	if (argcnt < 7) {
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
    
    freq           = (unsigned int)lua_tointeger(L, 1);
    band_width    = (unsigned char)lua_tointeger(L, 2);
    step_size     = (unsigned int)lua_tointeger(L, 3);
    step_num      = (unsigned int)lua_tointeger(L, 4);
    msr_step_num = (unsigned int)lua_tointeger(L, 5);
    samples       = (unsigned int)lua_tointeger(L, 6);
    delaytime     = (unsigned int)lua_tointeger(L, 7);
    
    ret = start_rx_desense_scan(freq, band_width, step_size, step_num, msr_step_num, samples, delaytime);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

static int ldsp_stop_rx_desense_scan(lua_State *L)
{
    int ret = -1;

    ret = stop_rx_desense_scan();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* DSP two way transmit interface */
static int ldsp_two_way_transmit_start(lua_State *L)
{
    unsigned int freq;    /* Transmit freq, value range in UHF, VHF or WLB */
    unsigned char band_width;  /* 0->12.5KHz, 1->25KHz */
    int16_t  power_level;  /* Signed 16-bit value represents power level in dBm times 100. 
                            For example,” -20.50 dBm” is specified as -2050. */
    int repeat_num;
    unsigned int on_time; 
    unsigned int off_time;
    
    int i;
    int ret = -1;
    int argcnt = 0;
    
	argcnt = lua_gettop(L);
	if (argcnt < 6) {
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
    
    freq = (unsigned int)lua_tointeger(L, 1);
    band_width = (unsigned char)lua_tointeger(L, 2);
    power_level = (int16_t)lua_tointeger(L, 3);
    repeat_num = (int)lua_tointeger(L, 4);
    on_time = (unsigned int)lua_tointeger(L, 5);
    off_time = (unsigned int)lua_tointeger(L, 6);
    
    ret = two_way_transmit_start(freq, band_width, power_level, repeat_num, on_time, off_time);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

static int ldsp_two_way_transmit_stop(lua_State *L)
{
    int ret = -1;

    ret = two_way_transmit_stop();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* Tia603 DSP audio rx and tx interface */
static int ldsp_audio_rx_start(lua_State *L)
{
    int ret = -1;

    ret = dsp_audio_rx_start();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

static int ldsp_audio_rx_stop(lua_State *L)
{
    int ret = -1;

    ret = dsp_audio_rx_stop();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

static int ldsp_audio_tx_start(lua_State *L)
{
    int ret = -1;

    ret = dsp_audio_tx_start();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

static int ldsp_audio_tx_stop(lua_State *L)
{
    int ret = -1;

    ret = dsp_audio_tx_stop();
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
static const struct luaL_reg dsp_lib[] = 
{
    {"load",				ldsp_load_image},
    {"release",			ldsp_release},
    {"stop",				ldsp_stop},
    
    /* single power measurement interface */
    {"start_rx_power_measurement",				ldsp_start_rx_power_measurement},
    {"get_period_power_msr_data",				ldsp_get_period_power_msr_data},
    
    /* DSP RX desense scan interface */
    {"start_rx_desense_scan",				ldsp_start_rx_desense_scan},
    {"stop_rx_desense_scan",				ldsp_stop_rx_desense_scan},
    
    /* DSP two way transmit interface */
    {"two_way_transmit_start",				ldsp_two_way_transmit_start},
    {"two_way_transmit_stop",				ldsp_two_way_transmit_stop},
    
    /* Tia603 DSP audio rx and tx interface */
    {"audio_rx_start",				ldsp_audio_rx_start},
    {"audio_rx_stop",				ldsp_audio_rx_stop},
    {"audio_tx_start",				ldsp_audio_tx_start},
    {"audio_tx_stop",				ldsp_audio_tx_stop},
    {NULL, NULL}
};

int luaopen_ldsp(lua_State *L) {
	luaL_register (L, LUA_LDSP_LIBNAME, dsp_lib);
	return 1;
}
