
#include "lnondsp.h"

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
    
    lua_pushboolean2table(L, "ret", TRUE);
    lua_pushinteger2table(L, "evt", evt.evt);
    lua_pushinteger2table(L, "evi", evt.evi);
    lua_pushinteger2table(L, "bufsize", evt.bufsize);
    #if 1
    if (NONDSP_EVT_BT == evt.evt) {
        switch(evt.evi) {
            case NONDSP_EVT_BT_ENABLE_STATE:
                lua_pushinteger2table(L, "status", (int32_t)*(uint32_t *)evt.buf);
                break;
            case NONDSP_EVT_BT_SCAN_ID:
            {
                uint8_t *pdata = evt.buf;
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
                
                idname = (struct btScanIdName *)evt.buf;
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
    #endif
    
    return 1;
}

static int lnondsp_register_callbacks(lua_State *L)
{
    registerNonDspEvtCb(nondsp_handle_event);
    return 0;
}

/* GPS test interface */
static int lnondsp_gps_enable(lua_State *L)
{
    int ret = -1;

    ret = gps_enable();
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

    ret = gps_disable();
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
	if (argcnt == 3 && lua_isstring(L, 1)) {
        pic_path = (char *)lua_tostring(L, 1);
        width = (uint32_t)lua_tointeger(L, 2);
        height = (uint32_t)lua_tointeger(L, 3);
    } else {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -2);
        return 2;    
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
    
    /* The time interval of showing two different images. */
    uint32_t range = 0; 
    
    int ret = -1;
    int argcnt = 0;
    
	argcnt = lua_gettop(L);
	if (argcnt == 2 && lua_isstring(L, 1)) {
        path = (char *)lua_tostring(L, 1);
        path_len = strlen(path);
        range = (uint32_t)lua_tointeger(L, 2);
    } else {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, -2);
        return 2;    
    }
    
    log_notice("lcd_slide_show_test_start(%s, %d, %d)\n", path, path_len, range);
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

    ret = disableBluetooth();
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

/* int32_t bt_txdata1_transmitter_start(uint16_t freq, char *packet_type);
 * start txdata1 transmitter for bluetooth radio test with max tx power.
 * @freq[in]           transmitter/receive frequency in MHz
 * @packet_type[in]    string of packet type.For examples:"DH1","DH3","DH5","2-DH1",... 
 * 
 * Return:  
 *    0: success
 *    -1: failed
 */
 static int lnondsp_bt_txdata1_transmitter_start(lua_State *L)
{
    uint16_t freq;
    char *packet_type;
    int ret = -1;
    int argcnt = 0;
    
	argcnt = lua_gettop(L);
	if (argcnt == 2 && lua_isnumber(L, 1) && lua_isstring(L, 2)) {
        freq = (uint16_t)lua_tointeger(L, 1);
        packet_type = (char *)lua_tostring(L, 2);
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

    ret = bt_txdata1_transmitter_start(freq, packet_type);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}


 
 
/* int32_t bt_txdata1_transmitter_stop(void);
 * stop txdata1 transmitter
 * 
 * return:
 * 0: success
 *  -1: failed
 */
static int lnondsp_bt_txdata1_transmitter_stop(lua_State *L)
{
    int ret = -1;

    ret = bt_txdata1_transmitter_stop();
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
#define NF(n)   {#n, lnondsp_##n}

    NF(register_callbacks), 
    NF(get_evt_number),
    NF(get_evt_item),
    
    NF(gps_enable), 
    NF(gps_disable), 
    
    #if 1
    NF(lcd_enable), 
    NF(lcd_disable), 
    NF(lcd_pattern_test), 
    NF(lcd_backlight_enable), 
    NF(lcd_backlight_disable), 
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
    NF(bt_txdata1_transmitter_start), 
    NF(bt_txdata1_transmitter_stop), 
    {NULL, NULL}
};

#define set_integer_const(key, value)	\
	lua_pushinteger(L, value);	\
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
    //MENTRY();
	return 1;
}
