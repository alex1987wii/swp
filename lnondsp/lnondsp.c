
#include "lnondsp.h"
#include <linux/input.h>

typedef struct nondsp_evt
{
    uint32_t evt;
    uint32_t evi;
    uint32_t bufsize;
    uint8_t *buf;
} nondsp_evt_t;

static list_head_t nondsp_list_head;

static int32_t nondsp_handle_event(uint32_t evt, uint32_t evi, uint32_t evtBufSize, uint8_t *evtBuf)
{
    nondsp_evt_t *evt_info = NULL;
    list_head_t *index = NULL;

    log_notice("nondsp event generate, evt %d evi %d size %d\n", evt, evi, evtBufSize);
    index = list_head_creat();
    if (NULL == index) {
        log_err("nondsp_handle_event, list_head_creat index fail\n");
        return -1;
    }
    list_head_init(index);

    evt_info = malloc(sizeof(nondsp_evt_t));
    if (NULL == evt_info) {
            log_err("nondsp_handle_event, malloc memory %d fail\n", sizeof(nondsp_evt_t));
            free(index);
            index = NULL;
            return -1;
    }

    evt_info->evt = evt;
    evt_info->evi = evi;
    evt_info->bufsize = evtBufSize;

    evt_info->buf = malloc(evtBufSize);
    if (NULL == evt_info->buf) {
            log_err("nondsp_handle_event, malloc memory %d fail\n", evtBufSize);
            free(evt);
            free(index);
            return -1;
    }

    memcpy(evt_info->buf, evtBuf, evtBufSize);
    index->data = (void *)evt_info;
    list_add_tail(index, &nondsp_list_head);
    return 0;
}

static int lnondsp_get_evt_number(lua_State *L)
{
    lua_pushinteger(L, get_list_number(&nondsp_list_head));
    return 1;
}

static int lnondsp_get_evt_item(lua_State *L)
{
    int i = 0;
    int index_num;
    list_head_t *index = NULL;
    nondsp_evt_t evt;
    void *pbuf = NULL;
    int argcnt = 0;

    argcnt = lua_gettop(L);
    if (argcnt != 1) {
        log_err("lnondsp_get_evt_item argcnt != 1\n");
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

    index = get_list_item(index_num, &nondsp_list_head);
    if ((NULL == index) || list_is_head(index, &nondsp_list_head)) {
        lua_newtable(L);
        lua_pushboolean2table(L, "ret", FALSE);
        lua_pushinteger2table(L, "errno", -1);
        lua_pushstring2table(L, "errmsg", "thers is not list item\n");
        return 1;
    }

    memcpy(&evt, index->data, sizeof(nondsp_evt_t));

    lua_newtable(L);
    lua_pushstring(L, "buf");
    pbuf = lua_newuserdata(L, evt.bufsize);
    if (NULL == pbuf){
        log_err("lnondsp_get_evt_item lua_newuserdata return null\n");
        lua_pushnil(L);
        lua_settable(L, -3);

        lua_pushboolean2table(L, "ret", FALSE);
        lua_pushinteger2table(L, "errno", -2);
        lua_pushstring2table(L, "errmsg", "lnondsp_get_evt lua_newuserdata return null");
        return 1;
    }
    memcpy(pbuf, evt.buf, evt.bufsize);
    lua_settable(L, -3);

    list_del(index);
    free(index->data);
    free(index);
    free(evt.buf);

    lua_pushboolean2table(L, "ret", TRUE);
    lua_pushinteger2table(L, "evt", evt.evt);
    lua_pushinteger2table(L, "evi", evt.evi);
    lua_pushinteger2table(L, "bufsize", evt.bufsize);

    if (NONDSP_EVT_BT == evt.evt) {
        switch(evt.evi) {
            case NONDSP_EVT_BT_ENABLE_STATE:
                lua_pushinteger2table(L, "status", (int32_t)*(uint32_t *)pbuf);
                break;
            case NONDSP_EVT_BT_SCAN_ID:
            {
                uint8_t *pdata = pbuf;
                uint8_t id_cnt = *pdata;
                uint8_t addr[BLUETOOTH_ID_LEN + 1];
                addr[BLUETOOTH_ID_LEN] = '\0';
                pdata = pdata + 1;
                lua_pushinteger2table(L, "count", id_cnt);

                if (id_cnt > 0) {
                    lua_pushstring(L, "id");
                    lua_newtable(L);
                    for (i=0; i<id_cnt; i++) {
                        memset(addr, 0, BLUETOOTH_ID_LEN+1);
                        memcpy(addr, pdata[i*BLUETOOTH_ID_LEN], BLUETOOTH_ID_LEN);
                        lua_pushintegerkeystring2table(L, i+1, addr);
                    }
                    lua_settable(L, -3);
                }
            }
                break;
            case NONDSP_EVT_BT_SERIAL_DATA_RECV:

                break;
            case NONDSP_EVT_BT_DATA_RECV:

                break;
            case NONDSP_EVT_BT_DATA_SEND:

                break;
            case NONDSP_EVT_BT_SETUP_SERIAL_PORT:

                break;
            case NONDSP_EVT_BT_ESTABLISH_SCO:

                break;
            case NONDSP_EVT_BT_PING:

                break;
            case NONDSP_EVT_BT_RSSI:

                break;
            case NONDSP_EVT_BT_SCAN_ID_NAME:
            {
                struct btScanIdName *idname;
                uint8_t id[BLUETOOTH_ID_LEN + 1];
                uint8_t btname[256];
                id[BLUETOOTH_ID_LEN] = '\0';

                idname = (struct btScanIdName *)pbuf;
                lua_pushinteger2table(L, "count", idname->count);

                if (idname->count > 0) {
                    lua_pushstring(L, "id");
                    lua_newtable(L);
                    for (i=1; i<=idname->count; i++) {
                        memset(id, 0, BLUETOOTH_ID_LEN+1);
                        memcpy(id, idname->record[i-1].btId, BLUETOOTH_ID_LEN);
                        lua_pushintegerkeystring2table(L, i, id);
                    }
                    lua_settable(L, -3);

                    lua_pushstring(L, "name");
                    lua_newtable(L);
                    for (i=1; i<=idname->count; i++) {
                        memset(btname, 0, 256);
                        strcpy(btname, idname->record[i-1].btName);
                        lua_pushintegerkeystring2table(L, i, btname);
                    }
                    lua_settable(L, -3);
                }
            }
                break;
        }
    }
    else if (NONDSP_EVT_GPS == evt.evt){

        switch(evt.evi) {

            case NONDSP_EVT_GPS_REQ_RESULT:
            {
                gps_request_result_t *req_result = (gps_request_result_t *)pbuf;
                if (REQUEST_SUCCESS == req_result->state){
                    lua_pushboolean2table(L, "state", TRUE);
                } else {
                    lua_pushboolean2table(L, "state", FALSE);
                }
            }
                break;

            case NONDSP_EVT_GPS_FIRM_VER:
            {
                char *fw = (char *)pbuf;
                lua_pushstring2table(L, "fw_version", (unsigned char *)fw);
            }
                break;

            case NONDSP_EVT_GPS_FIXED:
            {
                gps_event_ttff_t *ttff = (gps_event_ttff_t *)pbuf;

                log_notice("lnondsp_get_evt_item: NONDSP_EVT_GPS_FIXED fixed: %d\n", ttff->fixed);
                lua_pushinteger2table(L, "fix_mode", ttff->fix_mode);   /* 0:not_seen, 1: no_fix, 2:2D fixed, 3:3D fixed */
                lua_pushboolean2table(L, "fixed", ttff->fixed);   /* 1: fixed, other: no fixed */
                lua_pushinteger2table(L, "TTFF", ttff->TTFF);           /* unit: second */
                lua_pushnumber2table(L, "lat", ttff->latitude);   /* unit: degree */
                lua_pushnumber2table(L, "lon", ttff->longitude); /* unit: degree */
                lua_pushnumber2table(L, "alt", ttff->altitude);   /* unit: meters */
            }
                break;

            case NONDSP_EVT_GPS_TEST_MODE_INFO:
            {
                gps_event_hw_test_mode_info_t *hw_test_info = (gps_event_hw_test_mode_info_t *)pbuf;
                log_notice("lnondsp_get_evt_item: NONDSP_EVT_GPS_TEST_MODE_INFO SVid: %d\n", hw_test_info->SVid);
                lua_pushinteger2table(L, "SVid", hw_test_info->SVid);
                lua_pushinteger2table(L, "Period", hw_test_info->Period);
                lua_pushinteger2table(L, "bit_sync_time", (unsigned int)hw_test_info->bit_sync_time);
                lua_pushinteger2table(L, "rtc_freq", (unsigned int)hw_test_info->rtc_freq);
                lua_pushnumber2table(L, "CNo_mean", hw_test_info->CNo_mean);
                lua_pushnumber2table(L, "CNo_sigma", hw_test_info->CNo_sigma);
                lua_pushnumber2table(L, "clock_drift", hw_test_info->clock_drift);
                lua_pushnumber2table(L, "clock_offset", hw_test_info->clock_offset);
                lua_pushinteger2table(L, "Abs_I20ms", hw_test_info->Abs_I20ms);
                lua_pushinteger2table(L, "Abs_Q20ms", hw_test_info->Abs_Q20ms);
                lua_pushnumber2table(L, "phase_lock_i", hw_test_info->phase_lock_indicator);
                lua_pushnumber2table(L, "agc", hw_test_info->agc);
                lua_pushnumber2table(L, "noise_figure", hw_test_info->noise_figure);
                lua_pushnumber2table(L, "drift_rate_in_ppb", hw_test_info->drift_rate_in_ppb);
                lua_pushnumber2table(L, "clock_offset_in_ppm", hw_test_info->clock_offset_in_ppm);
                lua_pushnumber2table(L, "Q_I_ratio", hw_test_info->Q_I_ratio);
            }
                break;
            default:
				log_notice("lnondsp_get_evt_item:GPS_EVT not-match evi: %d\n", evt.evi);
        }
    }
    else if (NONDSP_EVT_KEY == evt.evt) {
        switch(evt.evi) {
            case NONDSP_EVT_KEY_EVENT_REPORT:
            {
                struct parameter *key_event = (struct parameter *)pbuf;
                lua_pushinteger2table(L, "type", key_event->type);
                lua_pushinteger2table(L, "code", key_event->code);
                lua_pushinteger2table(L, "value", key_event->value);
            }
            break;
        }
    }

    return 1;
}

static int lnondsp_register_callbacks(lua_State *L)
{
    registerNonDspEvtCb(nondsp_handle_event);
    return 0;
}

/*  */
static int lnondsp_gps_enable(lua_State *L)
{
    int ret = -1;

    ret = bit_gps_enable();
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

    ret = bit_gps_disable();
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
 * #define GPS_COLD_START (0)
 * #define GPS_WARM_START (1)
 * #define GPS_HOT_START  (2)
 * extern int bit_gps_position_fixed(unsigned char resetMode)
 */
static int lnondsp_gps_req_fixed(lua_State *L)
{
    unsigned char resetMode;
    int ret = -1;
    int argcnt = 0;

    argcnt = lua_gettop(L);
    if (argcnt == 1 && lua_isnumber(L, 1)) {
        resetMode = (unsigned char)lua_tointeger(L, 1);
    } else {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -1);
        return 2;
    }

    ret = bit_gps_position_fixed(resetMode);
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
 * #define GPS_COLD_START (0)
 * #define GPS_WARM_START (1)
 * #define GPS_HOT_START  (2)
 * extern int bit_gps_restart(unsigned char resetMode);
 */
static int lnondsp_gps_restart(lua_State *L)
{
    unsigned char resetMode;
    int ret = -1;
    int argcnt = 0;

    argcnt = lua_gettop(L);
    if (argcnt == 1 && lua_isnumber(L, 1)) {
        resetMode = (unsigned char)lua_tointeger(L, 1);
    } else {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -1);
        return 2;
    }

    ret = bit_gps_restart(resetMode);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* extern int bit_gps_hw_test_enable(unsigned short SvID, unsigned short period); */
static int lnondsp_gps_hardware_test(lua_State *L)
{
    unsigned short SvID;
    unsigned short period;
    int ret = -1;
    int argcnt = 0;

    argcnt = lua_gettop(L);
    if (argcnt == 2 && lua_isnumber(L, 1) && lua_isnumber(L, 2)) {
        SvID = (unsigned short)lua_tointeger(L, 1);
        period = (unsigned short)lua_tointeger(L, 2);
    } else {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -1);
        return 2;
    }

    ret = bit_gps_hw_test_enable(SvID, period);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* extern int bit_gps_get_fix_status_once(void);
 * NONDSP_EVT_GPS_FIXED would return once */
static int lnondsp_gps_get_position_fix(lua_State *L)
{
    int ret = -1;

    ret = bit_gps_get_fix_status_once();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

#if 1
/* LCD test interface */
static int lnondsp_lcd_enable(lua_State *L)
{
    int ret = -1;

    ret = lcd_enable();
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

    ret = lcd_disable();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

static int lnondsp_lcd_set_backlight_level(lua_State *L)
{
    uint32_t level = 0;

    int ret = -1;
    int argcnt = 0;

    argcnt = lua_gettop(L);
    if (argcnt == 1 && lua_isnumber(L, 1)) {
        level = (uint32_t)lua_tointeger(L, 1);
    } else {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -2);
        return 2;
    }

    ret = lcd_set_bklight_level(level);
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
    if (argcnt == 3 && lua_isstring(L, 1)) {
        pic_path = (char *)lua_tostring(L, 1);
        width = (uint32_t)lua_tointeger(L, 2);
        height = (uint32_t)lua_tointeger(L, 3);
    } else {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -2);
        return 2;
    }

    ret = lcd_display_image_file(pic_path, width, height);
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

    /* The time interval of showing two different images. */
    uint32_t interval = 0;

    int ret = -1;
    int argcnt = 0;

    argcnt = lua_gettop(L);
    if (argcnt == 2 && lua_isstring(L, 1)) {
        path = (char *)lua_tostring(L, 1);
        path_len = strlen(path);
        interval = (uint32_t)lua_tointeger(L, 2);
    } else {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -2);
        return 2;
    }

    log_notice("lcd_slide_show_test_start(%s, %d, %d)\n", path, path_len, interval);
    ret = lcd_slideshow_start(path, path_len, interval);
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

    ret = lcd_slideshow_stop();
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

    ret = lcd_pattern_test();
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

    ret = led_config(ledid, period, percent, cycles);
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

    ret = led_selftest_start();
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

    ret = led_selftest_stop();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* start key pad event polling
 * int keypad_enable(void);
 * */
static int lnondsp_keypad_enable(lua_State *L)
{
    int ret = -1;

    ret = keypad_enable();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* close key pad event polling
 * int keypad_disable(void);
 * */
static int lnondsp_keypad_disable(lua_State *L)
{
    int ret = -1;

    ret = keypad_disable();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* key set back light interface
 * int set_backlight(int ctl);
 * */
static int lnondsp_keypad_set_backlight(lua_State *L)
{
    int ctl;

    int ret = -1;
    int argcnt = 0;

    argcnt = lua_gettop(L);
    if (argcnt != 1) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -1);
        return 2;
    }

    if (!lua_isboolean(L, 1)) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, 1);
        return 2;
    }

    ctl = (int)lua_toboolean(L, 1);

    ret = set_backlight(ctl);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

#ifdef CONFIG_PROJECT_G4_BBA
/**
 * int32_t vibrator_enable(void);
 * int32_t vibrator_set_time(uint32_t vib_time);
 * */
static int lnondsp_vibrator_enable(lua_State *L)
{
    int ret = -1;

    vibrator_set_time(0);
    ret = vibrator_enable();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/**
 * int32_t vibrator_disable(void);
 * */
static int lnondsp_vibrator_disable(lua_State *L)
{
    int ret = -1;

    ret = vibrator_disable();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/**
 *  Description:
 *      gsm_enable
 *  Params:
 *      None
 *  return:
 *      0: success
 *     -1: failed
 * int32_t gsm_enable();
 * */
static int lnondsp_gsm_enable(lua_State *L)
{
    int ret = -1;

    ret = fb_gsm_enable();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/**
 *  Description:
 *      gsm_disable
 *  Params:
 *      None
 *  return:
 *      0: success
 *     -1: failed
 * int32_t gsm_disable();
 * */
static int lnondsp_gsm_disable(lua_State *L)
{
    int ret = -1;

    ret = gsm_disable();
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
 * Function:set GSM band
 * Para:
 *     @band_type : type of gsm_band_t,include GSM_BAND_850_1900,GSM_BAND_900_1800 and GSM_BAND_850_900_1800_1900
 * Return:
 *     @ -1:   failed
 *     @ 0:    OK
 *  typedef enum{
 *      GSM_BAND_850_1900 =0,
 *      GSM_BAND_900_1800,
 *      GSM_BAND_850_900_1800_1900,
 *  }gsm_band_t;
 * int32_t gsm_set_bands(gsm_band_t band_type);
 */
static int lnondsp_gsm_set_band(lua_State *L)
{
    int ret = -1;
    int band_type;
    int argcnt;

    argcnt = lua_gettop(L);
    if (argcnt != 1) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -1);
        return 2;
    }

    band_type = (int) lua_tointeger(L, 1);

    ret = gsm_set_bands(band_type);
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
* Function:inquiry the network state of GSM module
* Para:
*     NULL
* Return:
*     @ -1:   failed
*     @ 0: not registered, the MT is not currently searching a new operator to register to
*     @ 1: registered, home network
*     @ 2: not registered, but the MT is currently searching a new operator to register to
*     @ 3: registration denied
*     @ 4: unknown (e.g. out of GERAN/UTRAN/E-UTRAN coverage)
*     @ 5: registered, roaming
*     @ 6: registered for "SMS only", home network (applicable only when <AcTStatus> indicates EUTRAN)
*     @ 7: registered for "SMS only", roaming (applicable only when <AcTStatus> indicates E-UTRAN)
*     @ 9: registered for "CSFB not preferred", home network (applicable only when <AcTStatus> indicates E-UTRAN)
*     @ 10: registered for "CSFB not preferred", roaming (applicable only when <AcTStatus> indicates E-UTRAN)
*   int32_t gsm_get_network_status(void);
*/
static int lnondsp_gsm_get_network_status(lua_State *L)
{
    int ret = -1;

    ret = gsm_get_network_status();
    lua_newtable(L);

    if (ret < 0) {
        lua_pushboolean2table(L, "ret", FALSE);
        lua_pushinteger2table(L, "code", ret);
        lua_pushstring2table(L, "msg", "not registered, the MT is not currently searching a new operator to register to");
        return 1;
    }

    lua_pushboolean2table(L, "ret", TRUE);
    lua_pushinteger2table(L, "code", ret);
    switch (ret) {
    case 0:
        lua_pushstring2table(L, "msg", "not registered, the MT is not currently searching a new operator to register to");
        break;
    case 1:
        lua_pushstring2table(L, "msg", "registered, home network");
        break;
    case 2:
        lua_pushstring2table(L, "msg", "not registered, but the MT is currently searching a new operator to register to");
        break;
    case 3:
        lua_pushstring2table(L, "msg", "registration denied");
        break;
    case 4:
        lua_pushstring2table(L, "msg", "unknown (e.g. out of GERAN/UTRAN/E-UTRAN coverage)");
        break;
    case 5:
        lua_pushstring2table(L, "msg", "registered, roaming");
        break;
    case 6:
        lua_pushstring2table(L, "msg", "registered for 'SMS only, home network (applicable only when <AcTStatus> indicates EUTRAN)");
        break;
    case 7:
        lua_pushstring2table(L, "msg", "registered for 'SMS only', roaming (applicable only when <AcTStatus> indicates E-UTRAN)");
        break;
    case 8:
        lua_pushstring2table(L, "msg", "not registered, the MT is not currently searching a new operator to register to");
        break;
    case 9:
        lua_pushstring2table(L, "msg", "registered for 'CSFB not preferred', home network (applicable only when <AcTStatus> indicates E-UTRAN)");
        break;
    case 10:
        lua_pushstring2table(L, "msg", "registered for 'CSFB not preferred', roaming (applicable only when <AcTStatus> indicates E-UTRAN)");
        break;
    default:
        lua_pushstring2table(L, "msg", "no such return code defined");
    }

    return 1;
}

 /*
* Function:Get GSM signal quality
* Para:
*    NULL
* Return:
*     @0: -113 dBm or less
*     @1: -111 dBm
*     @2..30: from -109 to -53 dBm with 2 dBm steps
*     @31: -51 dBm or greater
*     @99: not known or not detectable or currently not available
* unsigned int gsm_get_CSQ(void);
*/
static int lnondsp_gsm_get_CSQ(lua_State *L)
{
    int ret = -1;

    ret = gsm_get_CSQ();
    lua_newtable(L);

    if (ret < 0) {
        lua_pushboolean2table(L, "ret", FALSE);
        lua_pushinteger2table(L, "code", ret);
        lua_pushstring2table(L, "msg", "-113 dBm or less");
        return 1;
    }

    lua_pushboolean2table(L, "ret", TRUE);
    lua_pushinteger2table(L, "code", ret);
    switch (ret) {
    case 0:
        lua_pushstring2table(L, "msg", "not registered, the MT is not currently searching a new operator to register to");
        break;
    case 1:
        lua_pushstring2table(L, "msg", "-111 dBm");
        break;
    case 2:
        lua_pushstring2table(L, "msg", "not registered, but the MT is currently searching a new operator to register to");
        break;
    case 31:
        lua_pushstring2table(L, "msg", "-51 dBm or greater");
        break;
    case 99:
        lua_pushstring2table(L, "msg", "not known or not detectable or currently not available");
        break;

    default:
        if ((ret >= 2) || (ret <= 30)) {
            lua_pushstring2table(L, "msg", "-109 + (N * 2) dBm");
        } else {
            lua_pushstring2table(L, "msg", "no such return code defined");
        }
    }

    return 1;
}

/*
 * Function:Interface of getting register status for GSM module
 * Para:
 *    NULL
 * Return:
 *     @0  :gsm in idle
 *     @1  :gsm is initialing
 *     @2  :waiting for registered
 *     @3  :registered
 *     @4  :a call is incoming,the gsm module rings
 *     @5  :answered the incoming call
* int32_t gsm_get_register_status(void);
*/
static int lnondsp_gsm_get_register_status(lua_State *L)
{
    int ret = -1;

    ret = gsm_get_register_status();
    lua_newtable(L);

    if (ret < 0) {
        lua_pushboolean2table(L, "ret", FALSE);
        lua_pushinteger2table(L, "code", ret);
        lua_pushstring2table(L, "msg", "not registered, the MT is not currently searching a new operator to register to");
        return 1;
    }

    lua_pushboolean2table(L, "ret", TRUE);
    lua_pushinteger2table(L, "code", ret);
    switch (ret) {
    case 0:
        lua_pushstring2table(L, "msg", "gsm in idle");
        break;
    case 1:
        lua_pushstring2table(L, "msg", "gsm is initialing");
        break;
    case 2:
        lua_pushstring2table(L, "msg", "waiting for registered");
        break;
    case 3:
        lua_pushstring2table(L, "msg", "registered");
        break;
    case 4:
        lua_pushstring2table(L, "msg", "a call is incoming,the gsm module rings");
        break;
    case 5:
        lua_pushstring2table(L, "msg", "answered the incoming call");
        break;

    default:
        lua_pushstring2table(L, "msg", "no such return code defined");
    }

    return 1;
}


/*
* Function:start the process which keeps on sending GPRS datas through GSM module
* Para:
*     @remote_address:        the string pointer of remote server's IP address
*     @remote_port:           the server's port
*     @data:                  the data pointer you want to send
*     @data_len:              the data length
* Return:
*     @ 0:    success
*     @ -1:   failed
* int gsm_keep_sending_gprs_datas_start(unsigned char *remote_address, int remote_port, unsigned char *data, unsigned int data_len);
*/
static int lnondsp_gsm_keep_sending_gprs_datas_start(lua_State *L)
{
    unsigned char *remote_address = NULL;
    int remote_port;
    unsigned char *data = NULL;
    unsigned int data_len;

    int ret = -1;
    int argcnt = 0;

    argcnt = lua_gettop(L);
    if (argcnt != 3) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -1);
        return 2;
    }

    if (!lua_isstring(L, 1) || !lua_isnumber(L, 2) || !lua_isstring(L, 3)) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -3);
        return 2;
    }

    remote_address = (unsigned char *)lua_tostring(L, 1);
    remote_port = lua_tointeger(L, 2);
    data = (unsigned char *)lua_tostring(L, 3);
    data_len = strlen(data);

    ret = gsm_keep_sending_gprs_datas_start(remote_address, remote_port, data, data_len);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/**
* Function:stop the process which keeps on sending GPRS datas through GSM module
* Para:
*     NULL
* Return:
*     @ 0:    success
*     @ -1:   failed
* int gsm_keep_sending_gprs_datas_stop(void);
 * */
static int lnondsp_gsm_keep_sending_gprs_datas_stop(lua_State *L)
{
    int ret = -1;

    ret = gsm_keep_sending_gprs_datas_stop();
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
 * get the hardware state of ble module(check if the BLE HW is installed or uninstalled?),as FPL API
 *
 * RETURN VALUE:
 * & 1: HW has been installed
 * & 0: HW has NOT been installed
 * & -1: failed
 * int32_t get_ble_hw_state_fpl(void)
 */
static int lnondsp_ble_get_hw_state(lua_State *L)
{
    int ret = -1;

    ret = get_ble_hw_state_fpl();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        lua_pushinteger(L, ret);
        return 2;
    }
}

/*
 * set the power state of ble module,as FPL API
 * @state[in]    0: power off, 1: power on
 * & 0: success
 * & -1: failed
 * int32_t set_ble_power_state_fpl(uint32_t state);
 */
static int lnondsp_ble_set_power_state(lua_State *L)
{
    int pwr_on = 0;
    int ret = -1;
    int argcnt = 0;

    argcnt = lua_gettop(L);
    if (argcnt >= 1 && lua_isnumber(L, 1)) {
        pwr_on = (uint8_t *)lua_tointeger(L, 1);
    } else {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -1);
        return 2;
    }

    ret = set_ble_power_state_fpl(pwr_on);
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
 * get the power state of ble module,as FPL API
 * @state[out]    0: power off, 1: power on
 * & 0: success
 * & -1: failed
 * int32_t get_ble_power_state_fpl(uint32_t *state);
 */
static int lnondsp_ble_get_power_state(lua_State *L)
{
    uint32_t state;
    int ret = -1;

    ret = get_ble_power_state_fpl(&state);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        lua_pushinteger(L, (uint32_t)state);
        return 2;
    }
}

/*
 *get the current state of of ble module,as FPL API
 * @state[out]
 *    0 --> init
 *    1 --> advertising
 *    2 --> connected
 *    3 --> disconnected
 * & 0: success
 * & -1: failed
 * int32_t get_ble_con_state_fpl(uint8_t *state);
 */
static int lnondsp_ble_get_con_state(lua_State *L)
{
    uint8_t state;
    int ret = -1;

    ret = get_ble_con_state_fpl(&state);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        lua_pushinteger(L, (uint32_t)state);
        return 2;
    }
}

/*
 * get the state of ble data-sending,as FPL API
 * @err[in]
 *                0:no error;
 *      -1:data transfer error;
 *      -2:state err,e.g.the connection is set down when datas are transfering
 *      -3:operation err,e.g.can not open the file
 * void get_ble_send_status_fpl(int32_t *error);
 */
static int lnondsp_ble_get_send_status(lua_State *L)
{
    int32_t state;
    int ret = -1;
    char *msg[] = {
        "no error",
        "data transfer error",
        "state err,e.g.the connection is set down when datas are transfering",
        "operation err,e.g.can not open the file"};

    ret = get_ble_send_status_fpl(&state);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        if ((ret < -3) || (ret > 0)) {
            lua_pushstring(L, "unknown error");
        } else {
            lua_pushstring(L, msg[-ret]);
        }
        return 3;
    } else {
        lua_pushboolean(L, TRUE);
        lua_pushinteger(L, (uint32_t)state);
        return 2;
    }
}

/*
 * start to send data to another ble device,as FPL API
 * & 0: success
 * & -1: failed
 * int32_t ble_send_start_fpl(void);
 */
static int lnondsp_ble_send_start(lua_State *L)
{
    int ret = -1;

    ret = ble_send_start_fpl();
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
 * stop to send data to another ble device,as FPL API
 * & 0: success
 * & -1: failed
 * int32_t ble_send_stop_fpl(void);
 */
static int lnondsp_ble_send_stop(lua_State *L)
{
    int ret = -1;

    ret = ble_send_stop_fpl();
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
 * int32_t bt_enable(uint8_t mode);
 *  Description:
 *      enable bluetooth module, no block
 *  Params:
 *      @mode[in]     BT_HIGH_SPEED/BT_LOW_SPEED/BT_DUT_MODE/BT_POWER_ON_ONLY
 *  return:
 *      0: success
 *     -1: failed
 * */
static int lnondsp_bt_enable(lua_State *L)
{
    uint8_t speed_type;

    int ret = -1;
    int argcnt = 0;

    argcnt = lua_gettop(L);
    if (argcnt != 1) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -1);
        return 2;
    }

    if (!lua_isnumber(L, 1)) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, 1);
        return 2;
    }

    speed_type = (uint8_t)lua_tointeger(L, 1);

    ret = bt_enable(speed_type);
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
 * int32_t bt_enable_block(uint8_t mode);
 *  Description:
 *      enable bluetooth module with block
 *  Params:
 *      @mode[in]     BT_HIGH_SPEED/BT_LOW_SPEED/BT_DUT_MODE/BT_POWER_ON_ONLY
 *  return:
 *      0: success
 *     -1: failed
 * */
static int lnondsp_bt_enable_block(lua_State *L)
{
    uint8_t speed_type;

    int ret = -1;
    int argcnt = 0;

    argcnt = lua_gettop(L);
    if (argcnt != 1) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -1);
        return 2;
    }

    if (!lua_isnumber(L, 1)) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, 1);
        return 2;
    }

    speed_type = (uint8_t)lua_tointeger(L, 1);

    ret = bt_enable_block(speed_type);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t bt_disable(void);
 *  Description:
 *      disable bluetooth module
 *  Params:
 *      None
 *  return:
 *      0: success
 *     -1: failed
 * */
static int lnondsp_bt_disable(lua_State *L)
{
    int ret = -1;

    ret = bt_disable();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t bt_establish_sco(uint8_t *bt_id);
 *  Description:
 *      Establish a synchronous connection-oriented channel to transfer audio
 *      between U3 and Bluetooth Headset device. And the connection will not be
 *      closed until the Bluetooth module power down.
 *  Params:
 *      @bt_id[in]  bluetooth device id
 *  return:
 *      0: success
 *     -1: failed
 *  Note:
 *      block mode
 * */
static int lnondsp_bt_establish_sco(lua_State *L)
{
    uint8_t *bt_id = NULL;
    int ret = -1;
    int argcnt = 0;

    argcnt = lua_gettop(L);
    if (argcnt >= 1 && lua_isstring(L, 1)) {
        bt_id = (uint8_t *)lua_tostring(L, 1);
    } else {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -1);
        return 2;
    }

    ret = bt_establish_sco(bt_id);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t bt_establish_sco_block(uint8_t *bt_id);
 *  Description:
 *      Establish a synchronous connection-oriented channel to transfer audio
 *      between U3 and Bluetooth Headset device. And the connection will not be
 *      closed until the Bluetooth module power down.
 *  Params:
 *      @bt_id[in]  bluetooth device id
 *  return:
 *      0: success
 *     -1: failed
 *  Note:
 *      block mode
 * */
static int lnondsp_bt_establish_sco_block(lua_State *L)
{
    uint8_t *bt_id = NULL;
    int ret = -1;
    int argcnt = 0;

    argcnt = lua_gettop(L);
    if (argcnt >= 1 && lua_isstring(L, 1)) {
        bt_id = (uint8_t *)lua_tostring(L, 1);
    } else {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -1);
        return 2;
    }

    ret = bt_establish_sco_block(bt_id);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t bt_disconnect_sco(uint8_t *bt_id);
 *  Description:
 *      Disconnect a bluetooth synchronous connection-oriented channel
 *  Params:
 *      @bt_id[in]  bluetooth device id
 *  return:
 *      0: success
 *     -1: failed
 * */
static int lnondsp_bt_disconnect_sco(lua_State *L)
{
    uint8_t *bt_id = NULL;
    int ret = -1;
    int argcnt = 0;

    argcnt = lua_gettop(L);
    if (argcnt >= 1 && lua_isstring(L, 1)) {
        bt_id = (uint8_t *)lua_tostring(L, 1);
    } else {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -1);
        return 2;
    }

    ret = bt_disconnect_sco(bt_id);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t bt_talk_echo_start(void);
 *  Description:
 *      start bluetooth headset talk echo, must invoke after establish sco
 *  Params:
 *      None
 *  return:
 *      0: success
 *     -1: failed
 * */
static int lnondsp_bt_talk_echo_start(lua_State *L)
{
    int ret = -1;

    ret = bt_talk_echo_start();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t bt_talk_echo_stop(void);
 *  Description:
 *      stop bluetooth headset talk echo
 *  Params:
 *      None
 *  return:
 *      0: success
 *     -1: failed
 * */
static int lnondsp_bt_talk_echo_stop(lua_State *L)
{
    int ret = -1;

    ret = bt_talk_echo_stop();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t bt_ping(uint8_t *bt_id);
 *  Description:
 *      ping another bluetooth device
 *  Params:
 *      @bt_id[in] destination bluetooth address,18 Byte string
 *  return:
 *      0: success
 *     -1: failed
 * */
static int lnondsp_bt_ping(lua_State *L)
{
    uint8_t *bt_id = NULL;
    int ret = -1;
    int argcnt = 0;

    argcnt = lua_gettop(L);
    if (argcnt >= 1 && lua_isstring(L, 1)) {
        bt_id = (uint8_t *)lua_tostring(L, 1);
    } else {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -1);
        return 2;
    }

    ret = bt_ping(bt_id);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t bt_read_rssi(uint8_t *bt_id);
 *  Description:
 *      read RSSI(Received Signal Strength Indication)
 *  Params:
 *      @bt_id[in]      destination bluetooth address
 *  return:
 *      0: success
 *     -1: failed
 * */
static int lnondsp_bt_read_rssi(lua_State *L)
{
    uint8_t *bt_id = NULL;
    int ret = -1;
    int argcnt = 0;

    argcnt = lua_gettop(L);
    if (argcnt >= 1 && lua_isstring(L, 1)) {
        bt_id = (uint8_t *)lua_tostring(L, 1);
    } else {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -1);
        return 2;
    }

    ret = bt_read_rssi(bt_id);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t bt_serial_setup(uint8_t *bt_id, uint8_t port);
 *  Description:
 *      Send data to Bluetooth serial port
 *  Params:
 *      @data[in]       data to be sent
 *      @len[in]        data length
 *  return:
 *      0: success
 *     -1: failed
 * */
static int lnondsp_bt_serial_setup(lua_State *L)
{
    uint8_t *bt_id = NULL;
    uint8_t serial_port;
    int ret = -1;
    int argcnt = 0;

    argcnt = lua_gettop(L);
    if (argcnt >= 2 && lua_isstring(L, 1)) {
        bt_id = (uint8_t *)lua_tostring(L, 1);
    } else {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -1);
        return 2;
    }

    if (!lua_isnumber(L, 2)) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -2);
        return 2;
    }
    serial_port = (uint8_t)lua_tointeger(L, 2);

    ret = bt_serial_setup(bt_id, serial_port);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t bt_serial_send(uint8_t *data, uint32_t len);
 *  Description:
 *      Send data to Bluetooth serial port
 *  Params:
 *      @data[in]       data to be sent
 *      @len[in]        data length
 *  return:
 *      0: success
 *     -1: failed
 * */
static int lnondsp_bt_serial_send(lua_State *L)
{
    uint8_t *data = NULL;
    uint32_t len = 0;
    int ret = -1;
    int argcnt = 0;

    argcnt = lua_gettop(L);
    if (argcnt >= 2 && lua_isuserdata(L, 1)) {
        data = (uint8_t *)lua_touserdata(L, 1);
    } else {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -1);
        return 2;
    }

    if (!lua_isnumber(L, 2)) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -2);
        return 2;
    }
    len = (uint32_t)lua_tointeger(L, 2);

    ret = bt_serial_send(data, len);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t bt_serial_release(void);
 *  Description:
 *      Release Bluetooth Serial port connection
 *  Params:
 *      None
 *  return:
 *      0: success
 *     -1: failed
 * */
static int lnondsp_bt_serial_release(lua_State *L)
{
    int ret = -1;

    ret = bt_serial_release();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t bt_serial_recv(uint32_t len);
 *  Description:
 *      Request to receive data from Bluetooth serial port
 *  Params:
 *      @len[in]    length want to receive, must not greater than 4096
 *  return:
 *      0: success
 *     -1: failed
 * */
static int lnondsp_bt_serial_recv(lua_State *L)
{
    uint32_t len;
    int ret = -1;
    int argcnt = 0;

    argcnt = lua_gettop(L);
    if (argcnt >= 1 && lua_isnumber(L, 1)) {
        len = (uint32_t)lua_tointeger(L, 1);
    } else {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -1);
        return 2;
    }

    ret = bt_serial_recv(len);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t bt_get_state(uint8_t *state);
 *  Description:
 *      get Bluetooth state
 *  Params:
 *      @state[out]     bluetooth current state
 *                      0: disable; 1: searching; 2: connected
 *  return:
 *      0: success
 *     -1: failed
 * */
static int lnondsp_bt_get_state(lua_State *L)
{
    uint8_t state;
    int ret = -1;

    ret = bt_get_state(&state);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        lua_pushinteger(L, (uint32_t)state);
        return 2;
    }
}

/* int32_t bt_get_addr(uint8_t *bt_id);
 *  Description:
 *      get local bluetooth device address
 *  Params:
 *      @bt_id[out]     buffer to store bluetooth device address
 *  return:
 *      0: success
 *     -1: failed
 * */
static int lnondsp_bt_get_addr(lua_State *L)
{
    uint8_t addr[20];
    int ret = -1;

    memset(&addr, 0, 20);
    ret = bt_get_addr(&addr);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        lua_pushstring(L, (uint8_t *)addr);
        return 2;
    }
}

/* int32_t bt_set_addr(uint8_t *bt_id);
 *  Description:
 *      set local bluetooth device address
 *  Params:
 *      @bt_id[in]     bluetooth device address
 *  return:
 *      0: success
 *     -1: failed
 * */
static int lnondsp_bt_set_addr(lua_State *L)
{
    uint8_t *addr = NULL;
    int ret = -1;
    int argcnt = 0;

    argcnt = lua_gettop(L);
    if (argcnt >= 1 && lua_isstring(L, 1)) {
        addr = (uint8_t *)lua_tostring(L, 1);
    } else {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -1);
        return 2;
    }

    ret = bt_set_addr(addr);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t bt_simple_transmitter_start(uint16_t freq, uint16_t power_level);
 *  Description:
 *      start simple transmitter for bluetooth radio test
 *  Params:
 *      @freq[in]       transmitter/receive frequency in MHz
 *      @level[in]      transmitter/receive power amplifier
 *  return:
 *      0: success
 *     -1: failed
 * */
static int lnondsp_bt_simple_transmitter_start(lua_State *L)
{
    uint16_t freq;
    uint16_t power_level;
    int ret = -1;
    int argcnt = 0;

    argcnt = lua_gettop(L);
    if (argcnt >= 2 && lua_isnumber(L, 1)) {
        freq = (uint16_t)lua_tointeger(L, 1);
    } else {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -1);
        return 2;
    }

    if (!lua_isnumber(L, 2)) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -2);
        return 2;
    }

    power_level = (uint16_t)lua_tointeger(L, 2);

    ret = bt_simple_transmitter_start(freq, power_level);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t bt_simple_transmitter_stop(void);
 *  Description:
 *      stop simple transmitter
 *  Params:
 *      None
 *  return:
 *      0: success
 *     -1: failed
 * */
static int lnondsp_bt_simple_transmitter_stop(lua_State *L)
{
    int ret = -1;

    ret = bt_simple_transmitter_stop();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t bt_scan(void);
 *  Description:
 *      scan other bluetooth devices
 *  Params:
 *      None
 *  return:
 *      0: success
 *     -1: failed
 * */
static int lnondsp_bt_scan(lua_State *L)
{
    int ret = -1;

    ret = bt_scan();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t bt_scan_block(void);
 *  Description:
 *      scan other bluetooth devices
 *  Params:
 *      None
 *  return:
 *      0: success
 *     -1: failed
 * */
static int lnondsp_bt_scan_block(lua_State *L)
{
    int ret = -1;

    ret = bt_scan_block();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t bt_recv(uint32_t len);
 *  Description:
 *      send data to another bluetooth device
 *  Params:
 *      @bt_id[in]  destination bluetooth device address
 *      @data[in]   data to be send
 *      @len[in]    data len
 *  return:
 *      0: success
 *     -1: failed
 * */
static int lnondsp_bt_recv(lua_State *L)
{
    uint32_t len;
    int ret = -1;
    int argcnt = 0;

    argcnt = lua_gettop(L);
    if (argcnt >= 1 && lua_isnumber(L, 1)) {
        len = (uint32_t)lua_tointeger(L, 1);
    } else {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -1);
        return 2;
    }

    ret = bt_recv(len);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t bt_send(uint8_t *bt_id, uint8_t *data, uint32_t len);
 *  Description:
 *      send data to another bluetooth device
 *  Params:
 *      @bt_id[in]  destination bluetooth device address
 *      @data[in]   data to be send
 *      @len[in]    data len
 *  return:
 *      0: success
 *     -1: failed
 * */
static int lnondsp_bt_send(lua_State *L)
{
    uint8_t *bt_id = NULL;
    uint8_t *data = NULL;
    uint32_t len = 0;
    int ret = -1;
    int argcnt = 0;

    argcnt = lua_gettop(L);
    if (argcnt >= 3 && lua_isstring(L, 1)) {
        bt_id = (uint8_t *)lua_tostring(L, 1);
    } else {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -1);
        return 2;
    }

    if (!lua_isuserdata(L, 2)) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -2);
        return 2;
    }
    data = (uint8_t *)lua_touserdata(L, 2);

    if (!lua_isnumber(L, 3)) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -3);
        return 2;
    }
    len = (uint32_t)lua_tointeger(L, 3);

    ret = bt_send(bt_id, data, len);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t bt_record_start(uint8_t *filename);
 *  Description:
 *      record data come from bluetooth controller PCM
 *  Params:
 *      @filename[in]  file to store record data
 *  return:
 *      0: success
 *     -1: failed
 * */
static int lnondsp_bt_record_start(lua_State *L)
{
    uint8_t *name = NULL;
    int ret = -1;
    int argcnt = 0;

    argcnt = lua_gettop(L);
    if (argcnt >= 1 && lua_isstring(L, 1)) {
        name = (uint8_t *)lua_tostring(L, 1);
    } else {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -1);
        return 2;
    }

    ret = bt_record_start(name);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t bt_record_stop(void);
 *  Description:
 *      stop record
 *  Params:
 *      None
 *  return:
 *      0: success
 *     -1: failed
 * */
static int lnondsp_bt_record_stop(lua_State *L)
{
    int ret = -1;

    ret = bt_record_stop();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t bt_play_start(uint8_t *filename);
 *  Description:
 *      play PCM voice data
 *  Params:
 *      @filename[in]  file to play
 *  return:
 *      0: success
 *     -1: failed
 * */
static int lnondsp_bt_play_start(lua_State *L)
{
    uint8_t *name = NULL;
    int ret = -1;
    int argcnt = 0;

    argcnt = lua_gettop(L);
    if (argcnt >= 1 && lua_isstring(L, 1)) {
        name = (uint8_t *)lua_tostring(L, 1);
    } else {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -1);
        return 2;
    }

    ret = bt_play_start(name);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t bt_play_stop(void);
 *  Description:
 *      stop play
 *  Params:
 *      None
 *  return:
 *      0: success
 *     -1: failed
 * */
static int lnondsp_bt_play_stop(lua_State *L)
{
    int ret = -1;

    ret = bt_play_stop();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t bt_rftest_transmitter_start(char *rftest_type, uint16_t freq, char *packet_type);
 * start rftest transmitter for bluetooth radio test with max tx power.
 * @rftest_type[in]    the type of rftest,only support "TXDATA1" or "TXDATA2"
 * @freq[in]           transmitter/receive frequency in MHz
 * @packet_type[in]    string of packet type.For examples:"DH1","DH3","DH5","2-DH1",...
 *
 * Return:
 *    0: success
 *    -1: failed
 */
 static int lnondsp_bt_rftest_transmitter_start(lua_State *L)
{
    char *rftest_type;
    uint16_t freq;
    char *packet_type;
    int ret = -1;
    int argcnt = 0;

    argcnt = lua_gettop(L);
    if (argcnt == 3 && lua_isstring(L, 1) && lua_isnumber(L, 2) && lua_isstring(L, 3)) {
        rftest_type = (char *)lua_tostring(L, 1);
        freq = (uint16_t)lua_tointeger(L, 2);
        packet_type = (char *)lua_tostring(L, 3);
    } else {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -1);
        return 2;
    }

    ret = bt_rftest_transmitter_start(rftest_type, freq, packet_type);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t bt_rftest_transmitter_stop(void);
 * stop rftest transmitter
 *
 * return:
 * 0: success
 *  -1: failed
 */
static int lnondsp_bt_rftest_transmitter_stop(lua_State *L)
{
    int ret = -1;

    ret = bt_rftest_transmitter_stop();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

typedef struct key_action {
    int code;
    int value;
    char action[256];
} key_action_t;

static void *powerkey_process_thread(void *arg)
{
    int32_t ret = 0, i;
    int event0_fd;
    int32_t maxfd;
    fd_set readfds;

    #define POWER_KEY (0x27)
    struct input_event event[80];
    struct parameter key_event;

    if ((event0_fd = open("/dev/input/event0", O_RDWR | O_NONBLOCK)) < 0) {
        log_notice("open /dev/input/event0 failed\n");
        return -1;
    }

    pthread_detach(pthread_self());

    while (1) {
        maxfd = -1;
        FD_ZERO(&readfds);
        FD_SET(event0_fd, &readfds);
        maxfd = maxfd >= event0_fd ? maxfd : event0_fd;

        /* wait for key press */
        ret = select(maxfd + 1, &readfds, NULL, NULL, NULL);
        if (ret < 0) {
            log_notice("%s:select error:%s\n", __FUNCTION__, strerror(errno));
        }

        if (FD_ISSET(event0_fd, &readfds)) {
            if ((ret = read(event0_fd, event, sizeof(struct input_event))) < 0) {
                log_notice("read keys input event failed\n");
                continue;
            }

            for (i = 0; i < (int)(ret / sizeof(struct input_event)); i++) {
                if ((event[i].code == POWER_KEY) && (0 == event[i].value)) {
                     system("/bin/rm -f /userdata/Settings/set_fpl_mode.lua");
                     system("/sbin/poweroff");
                }
            }
        }
    }

    return ((void *)0);
}

/* maybe calling by thread */
static int lnondsp_start_powerkey_service(lua_State *L)
{
    int ret = 0;
    pthread_t polling_event_pthread;
    /* Start polling DSP Event. */
    ret = pthread_create(&polling_event_pthread, NULL, powerkey_process_thread, NULL);
    if (ret != 0) {
        log_err("error: %s \n", strerror(ret));
        lua_pushboolean(L, FALSE);
        return 1;
    }

    lua_pushboolean(L, TRUE);
    return 0;
}


 /***********************************************************************************************

                ************the following API for FPL**************

************************************************************************************************/

/*
 * interface for lua
 */
static const struct luaL_reg nondsp_lib[] =
{
#define NF(n)   {#n, lnondsp_##n}

    NF(register_callbacks),
    NF(get_evt_number),
    NF(get_evt_item),

    NF(gps_enable),
    NF(gps_disable),
    NF(gps_restart),
    NF(gps_get_position_fix),
    NF(gps_hardware_test),
    NF(gps_req_fixed),

    #if 1
    NF(lcd_enable),
    NF(lcd_disable),
    NF(lcd_set_backlight_level),
    NF(lcd_pattern_test),
    NF(lcd_slide_show_test_start),
    NF(lcd_slide_show_test_stop),
    NF(lcd_display_static_image),
    #endif

    NF(led_config),
    NF(led_selftest_start),
    NF(led_selftest_stop),

    NF(keypad_enable),
    NF(keypad_disable),
    NF(keypad_set_backlight),

    #ifdef CONFIG_PROJECT_G4_BBA

    NF(vibrator_enable),
    NF(vibrator_disable),

    NF(gsm_enable),
    NF(gsm_disable),
    NF(gsm_get_CSQ),
    NF(gsm_get_network_status),
    NF(gsm_get_register_status),
    NF(gsm_set_band),
    NF(gsm_keep_sending_gprs_datas_start),
    NF(gsm_keep_sending_gprs_datas_stop),

    NF(ble_get_hw_state),
    NF(ble_set_power_state),
    NF(ble_get_power_state),
    NF(ble_get_con_state),
    NF(ble_get_send_status),
    NF(ble_send_start),
    NF(ble_send_stop),
    #endif

    NF(bt_enable),
    NF(bt_enable_block),
    NF(bt_disable),
    NF(bt_establish_sco),
    NF(bt_establish_sco_block),
    NF(bt_disconnect_sco),
    NF(bt_talk_echo_start),
    NF(bt_talk_echo_stop),
    NF(bt_ping),
    NF(bt_read_rssi),
    NF(bt_serial_setup),
    NF(bt_serial_send),
    NF(bt_serial_recv),
    NF(bt_serial_release),
    NF(bt_get_state),
    NF(bt_get_addr),
    NF(bt_set_addr),
    NF(bt_simple_transmitter_start),
    NF(bt_simple_transmitter_stop),
    NF(bt_scan),
    NF(bt_scan_block),
    NF(bt_recv),
    NF(bt_send),
    NF(bt_record_start),
    NF(bt_record_stop),
    NF(bt_play_start),
    NF(bt_play_stop),
    NF(bt_rftest_transmitter_start),
    NF(bt_rftest_transmitter_stop),
    NF(start_powerkey_service),

    {NULL, NULL}
};

#define set_integer_const(key, value)   \
    lua_pushinteger(L, value);  \
    lua_setfield(L, -2, key)

#define MENTRY(_f) set_integer_const(#_f, _f)

int luaopen_lnondsp(lua_State *L) {
    luaL_register (L, LUA_LNONDSP_LIBNAME, nondsp_lib);
    list_head_init(&nondsp_list_head);

    /* bluetooth */
    MENTRY(BT_HIGH_SPEED);
    MENTRY(BT_LOW_SPEED);
    MENTRY(BT_DUT_MODE);
    MENTRY(BT_POWER_ON_ONLY);
    MENTRY(GPS_COLD_START);
    MENTRY(GPS_WARM_START);
    MENTRY(GPS_HOT_START);
    //MENTRY();
    return 1;
}
