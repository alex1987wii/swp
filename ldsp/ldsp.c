
#include "ldsp.h"

/**
 * dsp init interface, param0 is the fd of /dev/dspmaster, param1 is the absolute path of dsp image
 * int dsp_init(int dsp_master_fd, const char *image_path);
 */
static int ldsp_init(lua_State *L)
{
    const char *dspmasterpath = NULL;
    const char *imagepath = NULL;
    int dsp_master_fd = -1;
    int ret = -1;
    int argcnt = 0;
    
	argcnt = lua_gettop(L);
	if (argcnt != 2) {
        lua_pushnil(L);
        lua_pushstring(L, "ldsp_init argcnt != 2\n");
        return 2;
    }

	if ((!lua_isstring(L, 1)) && (!lua_isstring(L, 2))) {
        lua_pushnil(L);
        lua_pushstring(L, "ldsp_init arg[1|2] is not string\n");
        return 2;
    }
    dspmasterpath = (char *)lua_tostring(L, 1);
    imagepath      = (char *)lua_tostring(L, 2);
    dsp_master_fd = open(dspmasterpath, O_RDWR);
    if (dsp_master_fd < 0) {
        lua_pushnil(L);
        lua_pushstring(L, "ldsp_init cannot open sapmasterpath\n");
        return 2;
    }
    ret = dsp_init(dsp_master_fd, imagepath);
    if (ret != 0) {
        lua_pushnil(L);
        lua_pushstring(L, "ldsp_init dsp_init fail\n");
        return 2;
    } else {
        lua_pushinteger(L, dsp_master_fd);
        return 1;
    }
}

/**
 * stop dsp, but not close /dev/dspmaster device
 * int stop_dsp(int dsp_master_fd);
 */
 static int ldsp_stop(lua_State *L)
{
    int dsp_master_fd = -1;
    int ret = -1;
    int argcnt = 0;
    
	argcnt = lua_gettop(L);
	if (argcnt != 1) {
        lua_pushboolean(L, FALSE);
        lua_pushstring(L, "ldsp_init argcnt != 1\n");
        return 2;
    }

	if (!lua_isnumber(L, 1)) {
        lua_pushboolean(L, FALSE);
        lua_pushstring(L, "ldsp_init arg[1|2] is not string\n");
        return 2;
    }
    dsp_master_fd = (int)lua_tointeger(L, 1);

    ret = stop_dsp(dsp_master_fd);
    if (ret != 0) {
        lua_pushboolean(L, FALSE);
        lua_pushstring(L, "ldsp_init stop_dsp fail\n");
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* define by libbitdsp */
#if 0 
static int ldsp_load(lua_State *L)
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
    
    ret = bit_load_dsp_image(imagepath, path_len);
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

    ret = bit_release_dsp();
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

    ret = bit_stop_dsp();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}
#endif


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

#if ( defined (CONFIG_PROJECT_U4) || defined (CONFIG_PROJECT_G3) || defined (CONFIG_PROJECT_M1) || defined (CONFIG_PROJECT_M1RU) )
/* read/write DSP audio samples data interface, only use in u4/g3/g4
int read_dsp_audio_samples_data(unsigned int audio_data_size, unsigned char *buf);
int write_dsp_audio_samples_data(unsigned int audio_data_size, unsigned char *buf);
*/
static int ldsp_read_dsp_audio_samples_data(lua_State *L)
{
    unsigned int audio_data_size;    
    unsigned char *buf = NULL;
    
    int ret = -1;
    int argcnt = 0;
    
	argcnt = lua_gettop(L);
	if (argcnt != 2) {
        lua_pushboolean(L, FALSE);
        lua_pushstring(L, "ldsp_read_dsp_audio_samples_data argcnt != 2\n");
        return 2;
    }
    
    if (!lua_isnumber(L, 1)) {
        lua_pushboolean(L, FALSE);
        lua_pushstring(L, "ldsp_read_dsp_audio_samples_data arg[1] is not number\n");
        return 2;
    }
    
    if (!lua_islightuserdata(L, 2)) {
        lua_pushboolean(L, FALSE);
        lua_pushstring(L, "ldsp_read_dsp_audio_samples_data arg[2] is not buf\n");
        return 2;
    }
    
    audio_data_size = (int)lua_tointeger(L, 1);
    buf = (unsigned char *)lua_touserdata(L, 2);
    
    ret = read_dsp_audio_samples_data(audio_data_size, buf);
    if (ret != 0) {
        lua_pushboolean(L, FALSE);
        lua_pushstring(L, "ldsp_read_dsp_audio_samples_data read_dsp_audio_samples_data fail\n");
        return 2;
    }
    
    lua_pushboolean(L, TRUE);
    return 1;
}

static int ldsp_write_dsp_audio_samples_data(lua_State *L)
{
    unsigned int audio_data_size;
    unsigned char *buf = NULL;
    
    int ret = -1;
    int argcnt = 0;
    
	argcnt = lua_gettop(L);
	if (argcnt != 2) {
        lua_pushboolean(L, FALSE);
        lua_pushstring(L, "ldsp_write_dsp_audio_samples_data argcnt != 2\n");
        return 2;
    }
    
    if (!lua_isnumber(L, 1)) {
        lua_pushboolean(L, FALSE);
        lua_pushstring(L, "ldsp_write_dsp_audio_samples_data arg[1] is not number\n");
        return 2;
    }
    
    if (!lua_islightuserdata(L, 2)) {
        lua_pushboolean(L, FALSE);
        lua_pushstring(L, "ldsp_write_dsp_audio_samples_data arg[2] is not buf\n");
        return 2;
    }
    
    audio_data_size = (int)lua_tointeger(L, 1);
    buf = (unsigned char *)lua_touserdata(L, 2);
    
    ret = write_dsp_audio_samples_data(audio_data_size, buf);
    if (ret != 0) {
        lua_pushboolean(L, FALSE);
        lua_pushstring(L, "ldsp_read_dsp_audio_samples_data write_dsp_audio_samples_data fail\n");
        return 2;
    }
    
    lua_pushboolean(L, TRUE);
    return 1;
}

/**
 * int dsp_capture_process(int flag);
 * flag: true -> open the capture process
 *       false -> close the capture process
 */
static int ldsp_dsp_capture_process(lua_State *L)
{
    int flag;
    int i;
    int ret = -1;
    int argcnt = 0;
    
	argcnt = lua_gettop(L);
	if (argcnt != 1 {
        lua_pushboolean(L, FALSE);
        lua_pushstring(L, "ldsp_dsp_capture_process argcnt != 1\n");
        return 2;
    }

    if (!lua_isboolean(L, 1)) {
        lua_pushboolean(L, FALSE);
        lua_pushstring(L, "ldsp_dsp_capture_process arg[1] is not boolean\n");
        return 2;
    }
    
    flag = (int)lua_toboolean(L, 1);
    
    ret = dsp_capture_process(flag);
    if (ret != 0) {
        lua_pushboolean(L, FALSE);
        lua_pushstring(L, "ldsp_dsp_capture_process dsp_capture_process fail\n");
        return 2;
    }
    
    lua_pushboolean(L, TRUE);
    return 1;
}

/**
 * int dsp_delivery_process(int flag);
 * flag: true -> open the delivery process
 *       false -> close the delivery process
 */
static int ldsp_dsp_delivery_process(lua_State *L)
{
    int flag;
    int i;
    int ret = -1;
    int argcnt = 0;
    
	argcnt = lua_gettop(L);
	if (argcnt != 1 {
        lua_pushboolean(L, FALSE);
        lua_pushstring(L, "ldsp_dsp_delivery_process argcnt != 1\n");
        return 2;
    }

    if (!lua_isboolean(L, 1)) {
        lua_pushboolean(L, FALSE);
        lua_pushstring(L, "ldsp_dsp_delivery_process arg[1] is not boolean\n");
        return 2;
    }
    
    flag = (int)lua_toboolean(L, 1);
    
    ret = dsp_delivery_process(flag);
    if (ret != 0) {
        lua_pushboolean(L, FALSE);
        lua_pushstring(L, "ldsp_dsp_delivery_process dsp_delivery_process fail\n");
        return 2;
    }
    
    lua_pushboolean(L, TRUE);
    return 1;
}
#endif

/**
 * int start_audio_transfer(uint8_t src, uint8_t dest, uint8_t *path);
 */
static int ldsp_start_audio_transfer(lua_State *L)
{
    unsigned char src;
    unsigned char dest;
    unsigned char *path = NULL;
    
    int ret = -1;
    int argcnt = 0;
    
	argcnt = lua_gettop(L);
	if (argcnt != 3) {
        lua_pushboolean(L, FALSE);
        lua_pushstring(L, "ldsp_start_audio_transfer argcnt != 3\n");
        return 2;
    }
    
    if (!lua_isnumber(L, 1)) {
        lua_pushboolean(L, FALSE);
        lua_pushstring(L, "ldsp_start_audio_transfer arg[1] is not number\n");
        return 2;
    }
    
    if (!lua_isnumber(L, 2)) {
        lua_pushboolean(L, FALSE);
        lua_pushstring(L, "ldsp_start_audio_transfer arg[2] is not number\n");
        return 2;
    }
    
    if (!lua_isstring(L, 3)) {
        lua_pushboolean(L, FALSE);
        lua_pushstring(L, "ldsp_start_audio_transfer arg[3] is not string\n");
        return 2;
    }
    
    src  = (unsigned char)lua_tointeger(L, 1);
    dest = (unsigned char)lua_tointeger(L, 2);
    path = (unsigned char *)lua_touserdata(L, 3);
    
    ret = start_audio_transfer(src, dest, path);
    if (ret != 0) {
        lua_pushboolean(L, FALSE);
        lua_pushstring(L, "ldsp_start_audio_transfer start_audio_transfer fail\n");
        return 2;
    }
    
    lua_pushboolean(L, TRUE);
    return 1;
}

/**
 * int stop_audio_transfer(void);
 */
static int ldsp_stop_audio_transfer(lua_State *L)
{
    int ret = -1;

    ret = stop_audio_transfer();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/** Tia603 DSP audio rx and tx interface
 * int start_tia603_audio_rx(unsigned char dest, unsigned int freq, unsigned char bandwidth, 
 *      unsigned char emphasis, unsigned char scrambler, unsigned char expander);
 */
static int ldsp_audio_rx_start(lua_State *L)
{
    unsigned char dest;
    unsigned int freq;
    unsigned char bandwidth; 
    unsigned char emphasis;
    unsigned char scrambler;
    unsigned char expander;
    
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

    dest = (unsigned char)lua_tointeger(L, 1);
    freq = (unsigned int)lua_tointeger(L, 2);
    bandwidth = (unsigned char)lua_tointeger(L, 3);
    emphasis = (unsigned char)lua_tointeger(L, 4);
    scrambler = (unsigned char)lua_tointeger(L, 5);
    expander = (unsigned char)lua_tointeger(L, 6);
    
    ret = start_tia603_audio_rx(dest, freq, bandwidth, emphasis, scrambler, expander);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/** Tia603 DSP audio rx and tx interface
 * int stop_tia603_audio_rx(void);
 */
static int ldsp_audio_rx_stop(lua_State *L)
{
    int ret = -1;

    ret = stop_tia603_audio_rx();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/** Tia603 DSP audio rx and tx interface
 * int start_tia603_audio_tx(unsigned char src, unsigned int freq, unsigned char bandwidth, 
 *      short pwrlevel, unsigned char emphasis, unsigned char scrambler, unsigned char compressor, unsigned char management);
 */
static int ldsp_audio_tx_start(lua_State *L)
{
    unsigned char src;
    unsigned int freq;
    unsigned char bandwidth; 
    short pwrlevel;
    unsigned char emphasis;
    unsigned char scrambler;
    unsigned char compressor;
    unsigned char management;
    
    int i;
    int ret = -1;
    int argcnt = 0;
    
	argcnt = lua_gettop(L);
	if (argcnt < 8) {
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

    src = (unsigned char)lua_tointeger(L, 1);
    freq = (unsigned int)lua_tointeger(L, 2);
    bandwidth = (unsigned char)lua_tointeger(L, 3);
    pwrlevel = (short)lua_tointeger(L, 4);
    emphasis = (unsigned char)lua_tointeger(L, 5);
    scrambler = (unsigned char)lua_tointeger(L, 6);
    compressor = (unsigned char)lua_tointeger(L, 7);
    management = (unsigned char)lua_tointeger(L, 8);
    
    ret = start_tia603_audio_tx(src, freq, bandwidth, pwrlevel, emphasis, scrambler, compressor, management);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/** Tia603 DSP audio rx and tx interface
 * int stop_tia603_audio_tx(void);
 */
static int ldsp_audio_tx_stop(lua_State *L)
{
    int ret = -1;

    ret = stop_tia603_audio_tx();
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
#define NF(n)   {#n, ldsp_##n}
    NF(init),
    NF(stop),
/* define by libbitdsp */
#if 0 
    NF(release),
    NF(load),
    NF(release),
#endif

    /* single power measurement interface */
    NF(start_rx_power_measurement), 
    NF(get_period_power_msr_data), 
    
    /* DSP RX desense scan interface */
    NF(start_rx_desense_scan), 
    NF(stop_rx_desense_scan),
    
    /* DSP two way transmit interface */
    NF(two_way_transmit_start),
    NF(two_way_transmit_stop),
    
#if ( defined (CONFIG_PROJECT_U4) || defined (CONFIG_PROJECT_G3) || defined (CONFIG_PROJECT_M1) || defined (CONFIG_PROJECT_M1RU) )
    NF(read_dsp_audio_samples_data), 
    NF(write_dsp_audio_samples_data), 
    NF(dsp_capture_process), 
    NF(dsp_delivery_process), 
#endif
    NF(start_audio_transfer), 
    NF(stop_audio_transfer), 

    /* Tia603 DSP audio rx and tx interface */
    NF(audio_rx_start), 
    NF(audio_rx_stop), 
    NF(audio_tx_start), 
    NF(audio_tx_stop), 
    {NULL, NULL}
};

int luaopen_ldsp(lua_State *L) {
	luaL_register (L, LUA_LDSP_LIBNAME, dsp_lib);
	return 1;
}
