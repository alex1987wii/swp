
-- fcc.lua 

require "log"
require "ldsp"
require "baseband"

FCC_MODE = {
    title = "Front Panel", 
    tips  = "Select the test item, move and space to select", 
    multi_select_mode = true, 
    init_env = function (t)
        init_global_env()
    end, 

    action_map = {
        [1] = function (t)
            t.freq = t[1].freq
        end, 
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
    [1] = {
        title = "Freq", 
        tips  = "Select Freq", 
        multi_select_mode = false, 
        action_map = {
            [1] = function (t)
                t.freq =  global_freq_band.start + 125 * 1000
            end, 
            [2] = function (t)
                t.freq =  (global_freq_band.start + global_freq_band.last) / 2 + 125 * 1000
            end, 
            [3] = function (t)
                t.freq =  global_freq_band.last - 875 * 1000
            end, 
            [4] = get_para_func("freq", "Freq(Hz)"), 
        }, 
        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end, 
        "Low frequency in MHz", 
        "Mid frequency in MHz", 
        "High frequency in MHz", 
        "Enter freq (Hz)", 
    }, 
    [2] = {
        title = "Band Width", 
        tips  = "Select Band Width", 
        multi_select_mode = false, 
        action = function (t)
            local bw_g = {1, 2} -- 0:16.25KHz 1:2.5KHz 2:25KHz 
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
            local powers = {0, 1, 2}
            t.power = powers[t.select_index]
        end, 
        "power profile 1",
        "power profile 2",
        "power profile 3", 
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
            local squelch_g = {1, 2, 3}  -- 0:none, 1:external speaker/mic, 2:bluetooth 
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
                t.modulation = 1
            end, 
            [2] = function (t)
                t.modulation = t[2].analog
            end, 
            [3] = function (t)
                t.modulation = t[3].digital
            end
        }, 
        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end, 
        [1] = "none", 
        [2] = {
            title = "Analog", 
            tips  = "Select Analog", 
            multi_select_mode = false, 
            action = function (t)
                local analog_g = {2, 3, 8}
                t.analog = analog_g[t.select_index]
            end, 
            "CTCSS (Tone = 250.3 Hz)", 
            "CDCSS (Code = 532)", 
            "MDC1200", 
        }, 
        [3] = {
            title = "Digital", 
            tips  = "Select Digital", 
            multi_select_mode = false, 
            action = function (t)
                local digital_g = {12, 13, 14, 15, 16, 17, 18}
                t.digital = digital_g[t.select_index]
            end, 
            "DVOA", 
            "TDMA Voice", 
            "TDMA Data", 
            "ARDS Voice", 
            "ARDS Data", 
            "P25 Voice", 
            "P25 Data", 
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
