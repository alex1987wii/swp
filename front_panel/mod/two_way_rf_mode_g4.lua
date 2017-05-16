
-- two_way_rf_mode.lua
require "log"
require "gps"
require "bluetooth"
require "baseband"
require "two_way_rf"
require "ble"

local freq_band = {
    VHF = {start=136 * 1000 * 1000, last = 174 * 1000 * 1000},
    U3_2ND = {start=763 * 1000 * 1000, last = 890 * 1000 * 1000},
    G4_BBA = {start=763 * 1000 * 1000, last = 890 * 1000 * 1000},
}

local device_type = device_type or read_config_mk_file("/etc/sconfig.mk", "Project")

if "u3" == tostring(device_type) then
    global_freq_band = freq_band.VHF
elseif "u3_2nd" == tostring(device_type) then
    global_freq_band = freq_band.U3_2ND
elseif "g4_bba" == tostring(device_type) then
    global_freq_band = freq_band.G4_BBA
else
    slog:err("not support device type : "..tostring(device_type))
end
slog:notice("front panel running -> device type : "..tostring(device_type))


RFT_MODE = {
    title = "Rx Desense Test",
    tips  = "Rx Desense Test",
    multi_select_mode = true,
    init_env = function (t)
        init_global_env()
    end,
    new_main_menu = function (t)
        local m_sub = create_main_menu(t)
        m_sub:show()
        m_sub:action()
    end,
    action_map = {
        [1] = defunc_rx_desense_action(1),
        [2] = defunc_enable_bt(2),
        [8] = defunc_rx_desense_spkr_action(8),
        [9] = defunc_enable_ble(9),
    },
    action = function (t)
        if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
            t.action_map[t.select_index](t)
        end
    end,
    [1] = "Rx Desense Scan",
    [2] = "Enable Bluetooth",
    [3] = "Disable LCD",
    [4] = "Show static image(LCD)",
    [5] = "Enable slide show",
    [6] = "Enable LED test",
    [7] = "Vibrator enable",
    [8] = "speaker enable",
    [9] = "Enable BLE",

    test_process = {
        [1] = defunc_rx_desense_scan.start(1),
        [2] = function (t) end,
        [3] = defunc_disable_lcd.start(3),
        [4] = defunc_lcd_display_static_image(4),
        [5] = defunc_lcd_slide_show_test.start(5),
        [6] = defunc_led_selftest.start(6),
        [7] = defunc_vibrator_test.start(7),
        [8] = defunc_rx_desense_spkr.start(8),
        [9] = defunc_rx_desense_ble_send_action.start(9),
    },
    stop_process = {
        [1] = defunc_rx_desense_scan.stop(1),
        [2] = function (t) end,
        [3] = defunc_disable_lcd.stop(3),
        [4] = function (t) end,
        [5] = defunc_lcd_slide_show_test.stop(5),
        [6] = defunc_led_selftest.stop(6),
        [7] = defunc_vibrator_test.stop(7),
        [8] = defunc_rx_desense_spkr.stop(8),
        [9] = defunc_rx_desense_ble_send_action.stop(9),
    },
    test_process_start = function (t)
        for i=1, table.getn(t) do
            if "function" == type(t.test_process[i]) then
                t.test_process[i](t)
            end
        end

        if t.select_status[1] then
            wait_for_rx_desense_scan_stop(t, 1)

            t:test_process_stop()
            t.test_process_start_call = false
            switch_self_refresh(true)
        end
    end,
    test_process_stop = function (t)
        for i=1, table.getn(t) do
            if "function" == type(t.stop_process[i]) then
                t.stop_process[i](t)
            end
        end
    end
}
