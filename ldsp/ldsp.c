
#include "ldsp.h"

extern int dsp_master_fd;
extern int dsp_audio_fd;

typedef struct dsp_evt
{
    uint32_t type;  /* 0 event, 1 exception */
    uint32_t bufsize;
    uint8_t *buf;
} dsp_evt_t;

static list_head_t dsp_list_head;

/**
 * dsp init interface, param0 is the fd of /dev/dspmaster, param1 is the absolute path of dsp image
 * int dsp_init(int dsp_master_fd, const char *image_path);
 */
static int ldsp_init(lua_State *L)
{
    const char *dspmasterpath = NULL;
    const char *imagepath = NULL;
    int dspmaster_fd = -1;
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
    dspmaster_fd = open(dspmasterpath, O_RDWR);
    if (dspmaster_fd < 0) {
        lua_pushnil(L);
        lua_pushstring(L, "ldsp_init cannot open sapmasterpath\n");
        return 2;
    }
    ret = dsp_init(dspmaster_fd, imagepath);
    if (ret != 0) {
        lua_pushnil(L);
        lua_pushstring(L, "ldsp_init dsp_init fail\n");
        return 2;
    } else {
        lua_pushinteger(L, dspmaster_fd);
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

static int ldsp_bit_launch_dsp(lua_State *L)
{
    int ret = -1;

    ret = bit_launch_dsp();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* DSP event callback function */
static int32_t dsp_event_handle(uint32_t bufsize, uint8_t *evtbuf)
{
    dsp_evt_t *evt = NULL;
    list_head_t *index = NULL;
    
    log_notice("dsp event generate, size %d\n", bufsize);
    index = list_head_creat();
    if (NULL == index) {
        log_err("dsp_event_handle, list_head_creat index fail\n");
        return -1;
    }
    list_head_init(index);
    
    evt = malloc(sizeof(dsp_evt_t));
    if (NULL == evt) {
            log_err("dsp_event_handle, malloc memory %d fail\n", sizeof(dsp_evt_t));
            free(index);
            index = NULL;
            return -1;
    }
    
    evt->type = 0;
    evt->bufsize = bufsize;
    
    evt->buf = malloc(bufsize);
    if (NULL == evt->buf) {
            log_err("dsp_event_handle, malloc memory %d fail\n", bufsize);
            free(evt);
            free(index);
            return -1;
    }
    
    memcpy(evt->buf, evtbuf, bufsize);
    index->data = (void *)evt;
    list_add_tail(index, &dsp_list_head);
    return 0;
}

/* DSP exception callback fuction */
static int32_t dsp_exception_handle(uint32_t bufsize, uint8_t *excepbuf)
{
    dsp_evt_t *evt = NULL;
    list_head_t *index = NULL;
    
    log_notice("dsp exception generate, size %d\n", bufsize);
    index = list_head_creat();
    if (NULL == index) {
        log_err("dsp_exception_handle, list_head_creat index fail\n");
        return -1;
    }
    list_head_init(index);
    
    evt = malloc(sizeof(dsp_evt_t));
    if (NULL == evt) {
            log_err("dsp_exception_handle, malloc memory %d fail\n", sizeof(dsp_evt_t));
            free(index);
            index = NULL;
            return -1;
    }
    
    evt->type = 1;
    evt->bufsize = bufsize;
    
    evt->buf = malloc(bufsize);
    if (NULL == evt->buf) {
            log_err("dsp_exception_handle, malloc memory %d fail\n", bufsize);
            free(evt);
            free(index);
            return -1;
    }
    
    memcpy(evt->buf, excepbuf, bufsize);
    index->data = (void *)evt;
    list_add_tail(index, &dsp_list_head);
    return 0;
}

static int ldsp_register_callbacks(lua_State *L)
{
    register_dsp_evt_callback(dsp_event_handle);
    register_dsp_excep_callback(dsp_exception_handle);
    return 0;
}

static void *polling_event_process_thread(void *arg)
{
    int32_t ret = 0;
    log_notice("creat event or exception polling thread successfully\n");
    pthread_detach(pthread_self());

    while (1) {
        polling_event_and_exception();
    }

    pthread_exit((void *)ret);
    return (void *)ret;
}

/* maybe calling by thread */
static int ldsp_start_dsp_service(lua_State *L)
{
    int ret = 0;
    pthread_t polling_event_pthread;
    /* Start polling DSP Event. */
    ret = pthread_create(&polling_event_pthread, NULL, polling_event_process_thread, NULL);
    if (ret != 0) {
        log_err("error: %s \n", strerror(ret));
        lua_pushboolean(L, FALSE);
        return 1;
    }

    lua_pushboolean(L, TRUE);
    return 0;
}

static int ldsp_get_evt_number(lua_State *L)
{
    lua_pushinteger(L, get_list_number(&dsp_list_head));
    return 1;
}

static int ldsp_get_evt_item(lua_State *L)
{
    int index_num;
    list_head_t *index = NULL;
    dsp_evt_t evt;
    void *pbuf = NULL;
    int argcnt = 0;
    
	argcnt = lua_gettop(L);
    if (argcnt != 1) {
        log_err("ldsp_get_evt_item argcnt != 1\n");
        lua_newtable(L);
        lua_pushboolean2table(L, "ret", FALSE);
        lua_pushinteger2table(L, "errno", -1);
        lua_pushstring2table(L, "errmsg", "argcnt != 1\n");
        return 1;
    }
    
    if (!lua_isnumber(L, 1)) {
        lua_newtable(L);
        lua_pushboolean2table(L, "ret", FALSE);
        lua_pushinteger2table(L, "errno", -1);
        lua_pushstring2table(L, "errmsg", "arg[1] is not number\n");
        return 1;
    }
    index_num = lua_tointeger(L, 1);

    index = get_list_item(index_num, &dsp_list_head);
    if ((NULL == index) || list_is_head(index, &dsp_list_head)) {
        lua_newtable(L);
        lua_pushboolean2table(L, "ret", FALSE);
        lua_pushinteger2table(L, "errno", -1);
        lua_pushstring2table(L, "errmsg", "thers is not list item\n");
        return 1;
    }
    
    memcpy(&evt, index->data, sizeof(dsp_evt_t));
    
    lua_newtable(L);
    lua_pushstring(L, "buf");
    pbuf = lua_newuserdata(L, evt.bufsize);
    if (NULL == pbuf){
        log_err("ldsp_get_evt_item lua_newuserdata return null\n");
        lua_pushnil(L);
        lua_settable(L, -3);
        
        lua_pushboolean2table(L, "ret", FALSE);
        lua_pushinteger2table(L, "errno", -2);
        lua_pushstring2table(L, "errmsg", "lnondsp_get_evt lua_newuserdata return null");
        return 1;
    }
    memcpy(pbuf, evt.buf, evt.bufsize);
    lua_settable(L, -3);
    
    lua_pushboolean2table(L, "ret", TRUE);
    lua_pushinteger2table(L, "type", evt.type);
    lua_pushinteger2table(L, "bufsize", evt.bufsize);
    return 1;
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
    unsigned int step_size;  /* 0Hz, 125000Hz, 25000Hz, 100000Hz and 1000000Hz */
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
    unsigned int start_freq;    /* Transmit freq, value range in UHF, VHF or WLB */
    unsigned char band_width;  /* 0->12.5KHz, 1->25KHz */
    int16_t  power_level;  /* Signed 16-bit value represents power level in dBm times 100. 
                            For example,” -20.50 dBm” is specified as -2050. */
    unsigned int start_delay;
    unsigned int step_size;
    int repeat_num;
    unsigned int on_time; 
    unsigned int off_time;
    
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
    
    start_freq = (unsigned int)lua_tointeger(L, 1);
    band_width = (unsigned char)lua_tointeger(L, 2);
    power_level = (int16_t)lua_tointeger(L, 3);
    start_delay = (int16_t)lua_tointeger(L, 4);
    step_size = (int16_t)lua_tointeger(L, 5);
    repeat_num = (int)lua_tointeger(L, 6);
    on_time = (unsigned int)lua_tointeger(L, 7);
    off_time = (unsigned int)lua_tointeger(L, 8);
    
    ret = two_way_transmit_start(start_freq, band_width, power_level, start_delay, step_size, repeat_num, on_time, off_time);
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

/* DSP duty cycle test interface */
static int ldsp_tx_duty_cycle_test_start(lua_State *L)
{
    unsigned int freq;    /* Transmit freq, value range in UHF, VHF or WLB */
    unsigned char band_width;  /* 0->12.5KHz, 1->25KHz */
    unsigned char power;  /* Signed 16-bit value represents power level in dBm times 100. 
                            For example,” -20.50 dBm” is specified as -2050. */
    unsigned char audio_path; /*  */
    unsigned char modulation; /*  */

    unsigned int trans_on_time; 
    unsigned int trans_off_time;
    
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
    
    freq = (unsigned int)lua_tointeger(L, 1);
    band_width = (unsigned char)lua_tointeger(L, 2);
    power = (unsigned char)lua_tointeger(L, 3);
    audio_path = (unsigned char)lua_tointeger(L, 4);
    modulation = (unsigned char)lua_tointeger(L, 5);
    trans_on_time = (unsigned int)lua_tointeger(L, 6);
    trans_off_time = (unsigned int)lua_tointeger(L, 7);
    
    ret = tx_duty_cycle_test_start(freq, band_width, power, audio_path, modulation, trans_on_time, trans_off_time);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

static int ldsp_tx_duty_cycle_test_stop(lua_State *L)
{
    int ret = -1;

    ret = tx_duty_cycle_test_stop();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/*  int fcc_start(unsigned int frequency, unsigned char band_width, unsigned char power,
                unsigned char audio_path, unsigned char squelch, unsigned char modulation) */
static int ldsp_fcc_start(lua_State *L)
{
    unsigned int freq;    /* Transmit freq, value range in UHF, VHF or WLB */
    unsigned char band_width;  /* 0->12.5KHz, 1->25KHz */
    unsigned char power;  /* Signed 16-bit value represents power level in dBm times 100. 
                            For example,” -20.50 dBm” is specified as -2050. */
    unsigned char audio_path; /*  */
    unsigned char squelch; /*  */

    unsigned char modulation; /*  */
    
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
    power = (unsigned char)lua_tointeger(L, 3);
    audio_path = (unsigned char)lua_tointeger(L, 4);
    squelch = (unsigned char)lua_tointeger(L, 5);
    modulation = (unsigned int)lua_tointeger(L, 6);
    
    ret = fcc_start(freq, band_width, power, audio_path, squelch, modulation);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

static int ldsp_fcc_stop(lua_State *L)
{
    int ret = -1;

    ret = fcc_stop();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* field test interface
 * int calibrate_radio_oscillator_start(void);
 * int get_original_afc_val(unsigned short *current_afc_val);
 * int calibrate_radio_oscillator_set_val(unsigned short afc_val);
 * int save_radio_oscillator_calibration(void);
 * int calibrate_radio_oscillator_stop(void);
 * int restore_default_radio_oscillator_calibration(void);
 */
static int ldsp_calibrate_radio_oscillator_start(lua_State *L)
{
    int ret = -1;

    ret = calibrate_radio_oscillator_start();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

static int ldsp_get_original_afc_val(lua_State *L)
{
    unsigned short current_afc_val;
    int ret = -1;

    ret = get_original_afc_val(&current_afc_val);
    if (ret < 0) {
        lua_newtable(L);
        lua_pushboolean2table(L, "ret", FALSE);
        lua_pushinteger2table(L, "errno", ret);
        lua_pushstring2table(L, "errmsg", "function call error");
        return 1;
    }
    
    lua_newtable(L);
    lua_pushboolean2table(L, "ret", TRUE);
    lua_pushinteger2table(L, "afc_val", current_afc_val);
    return 1;
}

static int ldsp_calibrate_radio_oscillator_set_val(lua_State *L)
{
    unsigned short afc_val;
    int ret = -1;
    int argcnt = 0;
    
	argcnt = lua_gettop(L);
    if (argcnt != 1) {
        log_err("ldsp_calibrate_radio_oscillator_set_val argcnt != 1\n");
        lua_newtable(L);
        lua_pushboolean2table(L, "ret", FALSE);
        lua_pushinteger2table(L, "errno", -1);
        lua_pushstring2table(L, "errmsg", "argcnt != 1");
        return 1;
    }
    
    if (!lua_isnumber(L, 1)) {
        lua_newtable(L);
        lua_pushboolean2table(L, "ret", FALSE);
        lua_pushinteger2table(L, "errno", -1);
        lua_pushstring2table(L, "errmsg", "arg[1] is not number\n");
        return 1;
    }
    afc_val = (unsigned short)lua_tointeger(L, 1);

    ret = calibrate_radio_oscillator_set_val(afc_val);
    if (ret < 0) {
        lua_newtable(L);
        lua_pushboolean2table(L, "ret", FALSE);
        lua_pushinteger2table(L, "errno", -1);
        lua_pushstring2table(L, "errmsg", "function call error");
        return 1;
    }

    lua_newtable(L);
    lua_pushboolean2table(L, "ret", TRUE);
    return 1;
}

static int ldsp_save_radio_oscillator_calibration(lua_State *L)
{
    int ret = -1;

    ret = save_radio_oscillator_calibration();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

static int ldsp_calibrate_radio_oscillator_stop(lua_State *L)
{
    int ret = -1;

    ret = calibrate_radio_oscillator_stop();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

static int ldsp_restore_default_radio_oscillator_calibration(lua_State *L)
{
    int ret = -1;

    ret = restore_default_radio_oscillator_calibration();
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
    int ret = -1;
    int argcnt = 0;
    
	argcnt = lua_gettop(L);
	if (argcnt != 1) {
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
    int ret = -1;
    int argcnt = 0;
    
	argcnt = lua_gettop(L);
	if (argcnt != 1) {
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
    path = (unsigned char *)lua_tostring(L, 3);
    
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

#if 0
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
#endif 

/*
 * interface for lua
 */
static const struct luaL_reg dsp_lib[] = 
{
#define NF(n)   {#n, ldsp_##n}
    NF(init),
    NF(stop),
    NF(bit_launch_dsp),
    
    /* for dsp event and exception */
    NF(register_callbacks),
    NF(start_dsp_service),

    NF(get_evt_number),
    NF(get_evt_item),
#if 0
    NF(read_dsp_evt),
    NF(read_dsp_exception),
#endif
/* define by libbitdsp */
#if 0 
    NF(release),
    NF(load),
    NF(release),
#endif

    /* single power measurement interface */
    NF(get_period_power_msr_data), 
    
    /* DSP RX desense scan interface */
    NF(start_rx_desense_scan), 
    NF(stop_rx_desense_scan),
    
    /* DSP two way transmit interface */
    NF(two_way_transmit_start),
    NF(two_way_transmit_stop),
    
    /* DSP tx duty cycle test interface */
    NF(tx_duty_cycle_test_start),
    NF(tx_duty_cycle_test_stop),
    
    NF(fcc_start),
    NF(fcc_stop),

    /* field test interface */
    NF(calibrate_radio_oscillator_start), 
    NF(get_original_afc_val), 
    NF(calibrate_radio_oscillator_set_val), 
    NF(save_radio_oscillator_calibration), 
    NF(calibrate_radio_oscillator_stop), 
    NF(restore_default_radio_oscillator_calibration), 
    
#if ( defined (CONFIG_PROJECT_U4) || defined (CONFIG_PROJECT_G3) || defined (CONFIG_PROJECT_M1) || defined (CONFIG_PROJECT_M1RU) )
    NF(read_dsp_audio_samples_data), 
    NF(write_dsp_audio_samples_data), 
    NF(dsp_capture_process), 
    NF(dsp_delivery_process), 
#endif

    NF(start_audio_transfer), 
    NF(stop_audio_transfer), 

    /* Tia603 DSP audio rx and tx interface */
#if 0
    NF(audio_rx_start), 
    NF(audio_rx_stop), 
    NF(audio_tx_start), 
    NF(audio_tx_stop), 
#endif

    {NULL, NULL}
};

#define set_integer_const(key, value)	\
	lua_pushinteger(L, value);	\
	lua_setfield(L, -2, key)

int luaopen_ldsp(lua_State *L) {
	luaL_register (L, LUA_LDSP_LIBNAME, dsp_lib);
    set_integer_const("dsp_master_fd", dsp_master_fd);
    set_integer_const("dsp_audio_fd", dsp_audio_fd);
    list_head_init(&dsp_list_head);
    
	return 1;
}
