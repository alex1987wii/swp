
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
    if (NULL == index) {
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
    memcpy(pbuf, &evt, evt.bufsize);
    lua_settable(L, -3);
    
    lua_pushboolean2table(L, "ret", TRUE);
    lua_pushinteger2table(L, "evt", evt.evt);
    lua_pushinteger2table(L, "evi", evt.evi);
    lua_pushinteger2table(L, "bufsize", evt.bufsize);
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
    
    /* The time interval of showing two different images. */
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

/* int32_t enableBluetoothReq(uint8_t speedType);
 * speed type value range:
 * 0: BT_LOW_SPEED (Uart Baud----38400bps)
 * 1: BT_HIGH_SPEED (Uart Baud----115200bps)
 * 2: BT_DUT_MODE 
 * 3: BT_POWER_ON_ONLY
 * */
static int lnondsp_enable_bluetooth_req(lua_State *L)
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
    
    ret = enableBluetoothReq(speed_type);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t disableBluetooth(void);
 * 
 * */
static int lnondsp_disable_bluetooth(lua_State *L)
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

/* int32_t scanOtherBluetoothIDReq(void);
 * 
 * */
static int lnondsp_scan_othen_bluetooth_id_req(lua_State *L)
{
    int ret = -1;

    ret = scanOtherBluetoothIDReq();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t pingBtReq(uint8_t *btId);
 * btId: 18 Byte string
 * */
static int lnondsp_ping_bt_req(lua_State *L)
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
    
    ret = pingBtReq(bt_id);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}


/* int32_t establishBtScoChannelReq(uint8_t *btId);
 * 
 * */
static int lnondsp_establish_bt_sco_channel_req(lua_State *L)
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
    
    ret = establishBtScoChannelReq(bt_id);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t talkEchoStart(void);
 * 
 * */
static int lnondsp_talk_echo_start(lua_State *L)
{
    int ret = -1;

    ret = talkEchoStart();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t talkEchoStop(void);
 * 
 * */
static int lnondsp_talk_echo_stop(lua_State *L)
{
    int ret = -1;

    ret = talkEchoStop();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t setupBTSerialPortReq(uint8_t *btId, uint8_t serialPort);
 * 
 * */
static int lnondsp_setup_bt_serial_port_req(lua_State *L)
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
    
    ret = setupBTSerialPortReq(bt_id, serial_port);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t releaseBTSerialPort(void);
 * 
 * */
static int lnondsp_release_bt_serial_port(lua_State *L)
{
    int ret = -1;

    ret = releaseBTSerialPort();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t btReceiveReq(uint32_t len);
 * 
 * */
static int lnondsp_bt_receive_req(lua_State *L)
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

    ret = btReceiveReq(len);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t btSendReq(uint8_t *btId, uint8_t * data, uint32_t len);
 * 
 * */
static int lnondsp_bt_send_req(lua_State *L)
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
    
    ret = btSendReq(bt_id, data, len);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t recvDataFromBTSerialPortReq(uint32_t len);
 * 
 * */
static int lnondsp_recv_data_from_bt_serial_port_req(lua_State *L)
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

    ret = recvDataFromBTSerialPortReq(len);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t sendDataToBTSerialPort(uint8_t *data, uint32_t len);
 * 
 * */
static int lnondsp_bt_send_data_to_bt_serial_port(lua_State *L)
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
    
    ret = sendDataToBTSerialPort(data, len);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t setLocalBluetoothtID(uint8_t *btId);
 * 
 * */
static int lnondsp_set_local_bt_id(lua_State *L)
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
    
    ret = setLocalBluetoothtID(bt_id);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t startSimpleTransmitter(uint16_t frequence, uint16_t txPowerLvl);
 * 
 * */

/* int32_t stopSimpleTransmitter(void);
 * 
 * */
static int lnondsp_stop_simple_transmitter(lua_State *L)
{
    int ret = -1;

    ret = stopSimpleTransmitter();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t disconnectBtScoChannel(uint8_t *btId);
 * 
 * */
static int lnondsp_disconnect_bt_sco_channel(lua_State *L)
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
    
    ret = disconnectBtScoChannel(bt_id);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t getBTState(uint8_t *state);
 * state value:
 * 0 power enable
 * 1 connect serial or ...
 * 2 other
 * */
static int lnondsp_get_bt_state(lua_State *L)
{
    uint8_t state;
    int ret = -1;
    
    ret = getBTState(&state);
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

/* int32_t getBluetoothID(uint8_t *btId);
 * 
 * */
static int lnondsp_get_bt_id(lua_State *L)
{
    uint8_t bt_id[20];
    int ret = -1;
    
    memset(bt_id, 0, 20);
    ret = getBluetoothID(&bt_id);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        lua_pushstring(L, (uint8_t *)bt_id);
        return 2;
    }
}

/* int32_t readBtRSSIReq(uint8_t *btId);
 * 
 * */
static int lnondsp_read_bt_rssi_req(lua_State *L)
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
    
    ret = readBtRSSIReq(bt_id);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t startBtRcd(uint8_t *name);
 * 
 * */
static int lnondsp_start_bt_rcd(lua_State *L)
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
    
    ret = startBtRcd(name);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t stopBtRcd(void);
 * 
 * */
static int lnondsp_stop_bt_rcd(lua_State *L)
{
    int ret = -1;

    ret = stopBtRcd();
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t startBtPlay(uint8_t *name);
 * 
 * */
static int lnondsp_start_bt_play(lua_State *L)
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
    
    ret = startBtPlay(name);
    if (ret < 0) {
        lua_pushboolean(L, FALSE);
        lua_pushinteger(L, ret);
        return 2;
    } else {
        lua_pushboolean(L, TRUE);
        return 1;
    }
}

/* int32_t stopBtPlay(void);
 * 
 * */
static int lnondsp_stop_bt_play(lua_State *L)
{
    int ret = -1;

    ret = stopBtPlay();
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
    
    NF(lcd_enable), 
    NF(lcd_disable), 
    NF(lcd_pattern_test), 
    NF(lcd_backlight_enable), 
    NF(lcd_backlight_disable), 
    NF(lcd_slide_show_test_start), 
    NF(lcd_slide_show_test_stop), 
    NF(lcd_display_static_image), 
    
    NF(led_config), 
    NF(led_selftest_start), 
    NF(led_selftest_stop), 

    NF(enable_bluetooth_req), 
    NF(disable_bluetooth), 
    NF(scan_othen_bluetooth_id_req), 
    NF(ping_bt_req), 
    NF(establish_bt_sco_channel_req), 
    NF(talk_echo_start), 
    NF(talk_echo_stop), 
    NF(setup_bt_serial_port_req), 
    NF(release_bt_serial_port), 
    NF(setup_bt_serial_port_req),
    NF(bt_receive_req), 
    NF(bt_send_req), 
    NF(recv_data_from_bt_serial_port_req), 
    NF(bt_send_data_to_bt_serial_port), 
    NF(set_local_bt_id), 
    NF(stop_simple_transmitter), 
    NF(disconnect_bt_sco_channel), 
    NF(get_bt_state), 
    NF(get_bt_id), 
    NF(read_bt_rssi_req), 
    NF(start_bt_rcd), 
    NF(stop_bt_rcd), 
    NF(start_bt_play), 
    NF(stop_bt_play), 

    {NULL, NULL}
};

int luaopen_lnondsp(lua_State *L) {
	luaL_register (L, LUA_LNONDSP_LIBNAME, nondsp_lib);
    list_head_init(&nondsp_list_head);
	return 1;
}
