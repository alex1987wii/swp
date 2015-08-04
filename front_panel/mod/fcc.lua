
-- fcc.lua 

require "log"
require "ldsp"
require "baseband"
require "posix"
require "opkey"

local device_type = device_type or read_config_mk_file("/etc/sconfig.mk", "Project")

wait_and_show_bat_status = function(t)
    local dev = "/dev/input/event0"
    local k = openkey(dev, "nonblock")
    if k == nil then
        slog:err("Err: open "..dev)
        return false
    end
    
    while true do
        local r_f, r_code = ldsp.fcc_battery_safe()
        -- slog:notice("fcc_battery_safe return code:"..tostring(r_code)) 
        if not r_f then
            switch_self_refresh(true)
            note_in_window_delay("battery not safe: "..tostring(r_code), 2)
            t.battery_err_show = true
        else
            if t.battery_err_show then
                switch_self_refresh(true)
                note_in_window_delay("battery safe", 2)
                t.battery_err_show = false
            end
        end
        
        local evts = k.readevts(lkey.event_size)
        if evts.ret then
			for k, v in ipairs(evts) do
                --note_in_window_delay("key code:value -> "..tostring(v.code)..":"..tostring(v.value), 2)
                
                --[[
                key code 33: *
                key code 34: #
                key value: 1 -> press, 0 -> release
                --]]
                if v.code == 34 and 0 == v.value then
                    t:test_process_stop()
                    t.test_process_start_call = false
                    switch_self_refresh(true)
                    return true
                end
            end 
        end
        
        --posix.sleep(1)
    end
end

defunc_fcc_freq_action_g4 = function (list_index)
    return function (t)
        local func = loadfile("/usr/local/share/lua/5.1/fcc_setting_g4.lua")
        if nil == func then
            slog:win("can not get the file: /usr/local/share/lua/5.1/fcc_setting_g4.lua")
            t.select_status[list_index] = false
            return
        end
        local setting = func()
        if "table" ~= type(setting) then
            slog:win("can not get setting from the file: /usr/local/share/lua/5.1/fcc_setting_g4.lua")
            t.select_status[list_index] = false
            return
        end
        
        if nil == setting.freq then
            slog:win("can not get freq in: /usr/local/share/lua/5.1/fcc_setting_g4.lua")
            t.select_status[list_index] = false
            return
        end
        
        t.freq = setting.freq
        t[list_index] = "freq "..tostring(setting.freq)
    end
end

FCC_MODE = {
    title = "Front Panel", 
    tips  = "Select the test item, move and space to select", 
    multi_select_mode = true, 
    init_env = function (t)
        init_global_env()
    end, 

    action_map = {
        [1] = get_para_func("freq", "Freq(Hz)"), 
        [2] = function (t) 
            t.band_width = t[2].band_width
        end, 
        [3] = function (t)
            t.power = t[3].power
        end, 
        [4] = function (t)
            t.audio_path = t[4].audio_path
        end, 
        [5] = function (t)
            t.squelch = t[5].squelch
        end, 
        [6] = function (t)
            t.modulation = t[6].modulation
        end, 
        [7] = defunc_enable_bt(7), 
    }, 
    action = function (t)
        if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
            t.action_map[t.select_index](t)
        end
        
        if nil ~= g_bt and "table" == type(g_bt.menu_tab) then
            for i=1, g_bt.menu_tab.devices_count do 
                if g_bt.menu_tab.devices_connect_status[i] then
                    t[4][3] = g_bt.menu_tab[i]
                end
            end
        end
    end, 
    [1] = "freq (Hz)", 
    [2] = {
        title = "Band Width", 
        tips  = "Select Band Width", 
        multi_select_mode = false, 
        action = function (t)
            local bw_g = {1, 2, 3} -- 1:2.5KHz 2:25KHz 3:20KHz(only u3_2nd) 
            t.band_width = bw_g[t.select_index]
        end,  
        "12.5 KHz", 
        "25 KHz", 
    }, 
    [3] = {
        title = "Power", 
        tips  = "Select Power", 
        multi_select_mode = false, 
        action = function (t)
            local powers = {1, 2, 3}
            t.power = powers[t.select_index]
        end, 
        "Low",
        "Mid",
        "High", 
    }, 
    [4] = {
        title = "Audio Path", 
        tips  = "Select Audio Path", 
        multi_select_mode = false, 
        action = function (t)
            local audio_path_g = {1, 2, 3}  -- 1:internal speaker/mic, 2:external speaker/mic, 3:bluetooth 
            t.audio_path = audio_path_g[t.select_index]
        end, 
        "Internal speaker / mic", 
        "External speaker / mic", 
        "BT device(show if pair)", 
    }, 
    [5] = {
        title = "Squelch", 
        tips  = "Select Squelch", 
        multi_select_mode = false, 
        action = function (t)
            local squelch_g = {0, 1, 2}  -- 0:none, 1:external speaker/mic, 2:bluetooth 
            t.squelch = squelch_g[t.select_index]
        end, 
        "none", 
        "normal", 
        "tight", 
    }, 
    [6] = {
        title = "Modulation", 
        tips  = "Select Modulation", 
        multi_select_mode = false, 
        action_map = {
            [1] = function (t)
                t.modulation = t[1].analog
            end, 
            [2] = function (t)
                t.modulation = t[2].digital
            end
        }, 
        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end,  
        [1] = {
            title = "Analog", 
            tips  = "Select Analog", 
            multi_select_mode = false, 
            action = function (t)
                local analog_g = {1, 2, 3, 8, 12}
                t.analog = analog_g[t.select_index]
            end, 
            "None (CSQ)", 
            "CTCSS (Tone = 250.3 Hz)", 
            "CDCSS (Code = 532)", 
            "MDC1200", 
            "DVOA", 
        }, 
        [2] = {
            title = "Digital", 
            tips  = "Select Digital", 
            multi_select_mode = false, 
            action = function (t)
                -- P25 Phase II == TDMA DATA -> 14 
                local digital_g = {13, 14, 15, 16, 17, 18, 14}
                t.digital = digital_g[t.select_index]
            end, 
            "TDMA Voice", 
            "TDMA Data", 
            "ARDS Voice", 
            "ARDS Data", 
            "P25 Voice Phase I", 
            "P25 Data Phase I", 
            "P25 Phase II", 
        }, 
    },  
    [7] = "Enable Bluetooth",
    [8] = "Enable GPS", 
    [9] = "Disable LCD", 
    [10]= "Show static image(LCD)", 
    [11]= "Enable slide show", 
    [12]= "Enable LED test", 

    test_process = {
        [1] = function (t)
            local cr = check_num_parameters(t.freq, t.band_width, t.power, t.audio_path, t.squelch, t.modulation)
            if cr.ret then
                local r_des, msgid_des = ldsp.fcc_start(t.freq, t.band_width, t.power, t.audio_path, t.squelch, t.modulation)
            else
                slog:err("parameter error: check "..cr.errno.." "..cr.errmsg)
            end
        end, 
        [7] = function (t) end, 
        [8] = defunc_enable_gps.start(8), 
        [9] = defunc_disable_lcd.start(9), 
        [10] = defunc_lcd_display_static_image(10), 
        [11] = defunc_lcd_slide_show_test.start(11), 
        [12] = defunc_led_selftest.start(12), 
    }, 
    stop_process = {
        [1] = function (t)
            local r_des, msgid_des = ldsp.fcc_stop()
        end, 
        [7] = function (t) end, 
        [8] = defunc_enable_gps.stop(8), 
        [9] = defunc_disable_lcd.stop(9), 
        [10] = function (t) end, 
        [11] = defunc_lcd_slide_show_test.stop(11), 
        [12] = defunc_led_selftest.stop(12), 

    }, 
    test_process_start = function (t)
        if "function" == type(t.test_process[1]) then
            t.test_process[1](t)
        end

        for i=7, 12 do
            if "function" == type(t.test_process[i]) then
                t.test_process[i](t)
            end
        end
        
        if "g4_bba" ~= tostring(device_type) then
            wait_and_show_bat_status(t)
        end
    end, 
    test_process_stop = function (t)
        if "function" == type(t.stop_process[1]) then
            t.stop_process[1](t)
        end
        for i=7, 12 do
            if "function" == type(t.stop_process[i]) then
                t.stop_process[i](t)
            end
        end
    end, 

}

if "g4_bba" == tostring(device_type) then
    FCC_MODE.action_map[1] = defunc_fcc_freq_action_g4(1)
end

if "u3_2nd" == tostring(device_type) then
    FCC_MODE[2][3] = "20 KHz"
end
