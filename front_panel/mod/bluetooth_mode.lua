
-- bluetooth_mode.lua 
require "log"
require "bluetooth"
require "gps"
require "two_way_rf"

Bluetooth_MODE = {
    title = "Bluetooth", 
    tips  = "Press * to start and # to end test", 
    multi_select_mode = true, 
    init_env = function (t)
        init_global_env()
    end, 
    action_map = {
        [1] = defunc_enable_bt(1), 
        [2] = function (t) 
            t.freq = t[2].freq
            t.data_rate = t[2].data_rate
        end, 
        [3] = defunc_2way_ch1_knob_action(3), 
    }, 
    action = function (t)
        if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
            t.action_map[t.select_index](t)
        end
    end, 
    [1] = "Find BT Device",
    [2] = {
        title = "Hardware test", 
        tips  = "Hardware test", 
        multi_select_mode = true, 

        action = function (t)
            t.freq = t[1].freq
            t.data_rate = t[2].data_rate
        end, 
        [1] = {
            title = "Frequency", 
            tips  = "Select Frequency", 
            multi_select_mode = false, 
            action = function (t)
                local freq_g = {2402, 2441, 2480}  
                t.freq = freq_g[t.select_index]
            end, 
            "2402 MHz", 
            "2441 MHz", 
            "2480 MHz", 
        }, 
        [2] = {
            title = "Data Rate", 
            tips  = "Select Data Rate(Packet Type)", 
            multi_select_mode = false, 
            action = function (t)
                t.data_rate = t[t.select_index].data_rate
            end, 
            [1] = {
                title = "Basic Data Rate", 
                tips  = "Select Basic Data Rate", 
                multi_select_mode = false, 
                action = function (t)
                    t.data_rate = t[t.select_index]
                end, 
                "DH1", 
                "DH3", 
                "DH5", 
            }, 
            [2] = {
                title = "Enhanced Data Rate", 
                tips  = "Select Enhanced Data Rate(Packet Type)", 
                multi_select_mode = false, 
                action = function (t)
                    t.data_rate = t[t.select_index]
                end, 
                "2-DH1", 
                "2-DH5", 
                "3-DH1",
                "3-DH5",  
            }, 
        }
    }, 
    [3] = "Enable 2way(ch1 Knob)", 
    [4] = "Enable GPS",  
        --[[ display to user'acquiring GPS signal'.Once acquired display to the user
              the 'latitude and longitude' of the fixes
        --]] 
    [5] = "Disable LCD", 
    [6] = "Show static image(LCD)", 
    [7] = "Enable slide show", 
    [8] = "Enable LED test", 
    
    test_process = {
        [1] = function (t) end, 
        [2] = defunc_bt_txdata1_transmitter.start(2), 
        [3] = defunc_2way_ch1_knob_settings.start(3), 
        [4] = defunc_enable_gps.start(4), 
        [5] = defunc_disable_lcd.start(5), 
        [6] = defunc_lcd_display_static_image(6), 
        [7] = defunc_lcd_slide_show_test.start(7), 
        [8] = defunc_led_selftest.start(8), 
    }, 
    stop_process = {
        [1] = function (t) end, 
        [2] = function (t)
            lnondsp.bt_txdata1_transmitter_stop()
        end, 
        [3] = defunc_2way_ch1_knob_settings.stop(3), 
        [4] = defunc_enable_gps.stop(4),  
        [5] = defunc_disable_lcd.stop(5), 
        [6] = function (t) end, 
        [7] = defunc_lcd_slide_show_test.stop(7), 
        [8] = defunc_led_selftest.stop(8), 

    }, 
    test_process_start = function (t)
        t.report = {}
        for i=1, 8 do
            if "function" == type(t.test_process[i]) then
                t.test_process[i](t)
            end
        end
    end, 
    test_process_stop = function (t)
        for i=1, 8 do
            if "function" == type(t.stop_process[i]) then
                t.stop_process[i](t)
            end
        end
    end, 

}
 
