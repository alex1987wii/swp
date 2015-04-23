
-- two_way_rf_mode.lua
require "log"
require "gps"
require "bluetooth"
require "baseband"
require "two_way_rf"

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
    title = "2Way RF Test", 
    tips  = "select and test", 
    multi_select_mode = false, 
    action = function (t)

    end, 

    [1] = {
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
            [1] = function (t)
                t.freq = t[1].freq
                t.band_width = t[1].band_width
                t.step_size = t[1].step_size
                t.step_num = t[1].step_num
                t.msr_step_num = t[1].msr_step_num
                t.samples = t[1].samples
                t.delaytime = t[1].delaytime
                if "g4_bba" ~= tostring(device_type) then
                    t.pfm_path = 0
                end
            end, 
            [2] = defunc_enable_bt(2), 
            [8] = defunc_rx_desense_spkr_action(8), 
        }, 
        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end, 
        [1] = {
            title = "Rx Desense Scan", 
            tips  = "Rx Desense Scan", 
            multi_select_mode = true, 

            action_map = {
                [1] = get_para_func("freq", "Freq(Hz)"), 
                [2] = function (t) 
                    t.band_width = t[2].band_width
                end, 
                [3] = function (t) 
                    t.step_size = t[3].step_size
                end, 
                [4] = get_para_func("step_num", "Step Num(0~1500)"), 
                [5] = get_para_func("msr_step_num", "msr_step_num(0~50)"), 
                [6] = get_para_func("samples", "samples(10~5000)"), 
                [7] = get_para_func("delaytime", "delaytime(0~100s)")
            }, 
            action = function (t)
                if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                    t.action_map[t.select_index](t)
                end
            end, 

            [1] = "Start Freq(Hz)",  -- 波段扫描起始频率 
            [2] = {
                title = "Band Width", 
                tips  = "Select Band Width", 
                multi_select_mode = false, 
                action = function (t)
                    local bw_g = {0, 1} -- 0:12.5KHz 1:25KHz 
                    t.band_width = bw_g[t.select_index]
                end, 

                "12.5 KHz", 
                "25 KHz", 
            }, 
            [3] = {  -- 波段扫描步长 
                title = "Step size", 
                tips  = "Select Step size", 
                multi_select_mode = false, 
                action = function (t)
                    local step_size_g = {
                        0, 
                        2.5 * 1000, 
                        6.25 * 1000, 
                        12.5 * 1000, 
                        25 * 1000, 
                        100 * 1000, 
                        1000 * 1000, 
                    }
                    t.step_size = step_size_g[t.select_index]
                end, 

                "0    Hz", 
                "2.5  KHz", 
                "6.25 KHz", 
                "12.5 KHz", 
                "25   KHz", 
                "100  KHz", 
                "1    MHz", 
            }, 
            [4] = "Step Num(0~1500)",  -- 扫描波段的个数 
            [5] = "msr_step_num(0~50)",  -- 每一个波段measure次数 
            [6] = "samples(10~5000)", -- 测量的samples值 
            [7] = "delaytime(0~100s)", -- 每个波段measure的间隔时间，有效值范围 
        }, 
        [2] = "Enable Bluetooth", 
        [3] = "Disable LCD", 
        [4] = "Show static image(LCD)", 
        [5] = "Enable slide show", 
        [6] = "Enable LED test", 
        [7] = "Enable GPS", 
        [8] = "speaker enable", 

        test_process = {
            [1] = defunc_rx_desense_scan.start(1), 
            [2] = function (t) end, 
            [3] = defunc_disable_lcd.start(3), 
            [4] = defunc_lcd_display_static_image(4), 
            [5] = defunc_lcd_slide_show_test.start(5), 
            [6] = defunc_led_selftest.start(6), 
            [7] = defunc_enable_gps.start(7), 
            [8] = defunc_rx_desense_spkr.start(8), 
        }, 
        stop_process = {
            [1] = defunc_rx_desense_scan.stop(1), 
            [2] = function (t) end, 
            [3] = defunc_disable_lcd.stop(3), 
            [4] = function (t) end, 
            [5] = defunc_lcd_slide_show_test.stop(5), 
            [6] = defunc_led_selftest.stop(6), 
            [7] = defunc_enable_gps.stop(7), 
            [8] = defunc_rx_desense_spkr.stop(8), 

        }, 
        test_process_start = function (t)
            t.report = {}
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
        end, 
    }, 
    [2] = {
        title = "Rx Antenna Gain Test", 
        tips  = "* start; up down key move to config", 
        multi_select_mode = true, 
        init_env = function (t)
            init_global_env()
        end, 
        new_main_menu = function (t)
            local m_sub = create_main_menu(t)
            m_sub:show()
            m_sub:action()
        end, 
        step_num = 1,  
        step_size = 0, 
        action_map = {
            [1] = get_para_func("freq", "Start freq(Hz)"), 
            [2] = function (t) 
                t.band_width = t[2].band_width
            end, 
            [3] = get_para_func("msr_step_num", "msr_step_num(0~50)"), 
            [4] = get_para_func("samples", "samples(10~5000)"), 
            [5] = get_para_func("delaytime", "delaytime(0~100s)"), 
        }, 
        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end, 

        [1] = "Start freq(Hz)",  -- 波段扫描起始频率 
        [2] = {
            title = "Band Width", 
            tips  = "Select Band Width", 
            multi_select_mode = false, 
            action = function (t)
                local bw_g = {0, 1} -- 0:12.5KHz 1:25KHz 
                t.band_width = bw_g[t.select_index]
            end, 

            "12.5 KHz", 
            "25 KHz", 
        }, 
        [3] = "msr_step_num(0~50)",  -- 每一个波段measure次数 
        [4] = "samples(10~5000)", -- 测量的samples值 
        [5] = "delaytime(0~100s)", -- 每个波段measure的间隔时间，有效值范围 
        
        test_process_start = function (t)
            local cr = check_num_parameters(t.freq, t.band_width, t.step_size, t.step_num, t.msr_step_num, t.samples, t.delaytime)
            if cr.ret then
                local r_des, msgid_des = ldsp.start_rx_desense_scan(t.freq, t.band_width, t.step_size, t.step_num, t.msr_step_num, t.samples, t.delaytime)
            else
                slog:err("parameter error: check "..cr.errno.." "..cr.errmsg)
                return false
            end
            
            wait_for_rx_desense_scan_stop(t, 1)
            
            t:test_process_stop()
            t.test_process_start_call = false
            switch_self_refresh(true)
        end, 
        
        test_process_stop = function (t)
            local r_des, msgid_des = ldsp.stop_rx_desense_scan()
        end
    }, 
    [3] = {
        title = "Tx with a duty cycle", 
        tips  = "Tx only with a settable duty cycle", 
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
                t.modulation = t[5].modulation
            end, 
            [6] = function (t)
                t.trans_on_time = t[6].trans_on_time
                t.trans_off_time = t[6].trans_off_time
            end, 
        }, 
        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
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
                local bw_g = {1, 2} -- 0:6.25KHz 1:12.5KHz 2:25KHz 
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
            "Power profile 1",
            "Power profile 2",
            "Power profile 3",
        }, 
        [4] = {
            title = "Audio Path", 
            tips  = "Select Audio Path", 
            multi_select_mode = false, 
            action = function (t)
                local audio_path_g = {1, 2}
                t.audio_path = audio_path_g[t.select_index]
            end, 
            "Internal mic", 
            "External mic", 
        }, 
        [5] = {
            title = "Modulation", 
            tips  = "Select Modulation", 
            multi_select_mode = false, 
            action = function (t)
                local modulation_g = {1, 2, 3, 4, 5, 8}
                t.modulation = modulation_g[t.select_index]
            end, 
            "none", 
            "CTCSS", 
            "CDCSS", 
            "2 tone", 
            "5/6 tone", 
            --"Modem(Digital 4FSK)", 
            "MDC1200", 
            --"DTMF", 
        }, 
        [6] = {
            title = "Tx ON/OFF Time Setting", 
            tips  = "Select and input the start/stop time", 
            multi_select_mode = true, 
            action_map = {
                [1] = get_para_func("trans_on_time", "Tx on time"), 
                [2] = get_para_func("trans_off_time", "Tx off time"), 
            }, 
            action = function (t)
                if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                    t.action_map[t.select_index](t)
                end
            end, 
            "Tx on time(s)", 
            "Tx off time(s)", 
        }, 
        
        test_process_start = function (t)
            local cr = check_num_parameters(t.freq, t.band_width, t.power, t.audio_path, t.modulation, t.trans_on_time, t.trans_off_time)
            if cr.ret then
                local r_des, msgid_des = ldsp.tx_duty_cycle_test_start(t.freq, t.band_width, t.power, t.audio_path, t.modulation, t.trans_on_time, t.trans_off_time)
                if not r_des then
                    slog:err("call ldsp.two_way_transmit_start fail: "..tostring(msgid_des))
                end
            else
                slog:err("parameter error: check "..tostring(cr.errno).." "..tostring(cr.errmsg))
            end
            
        end, 
        
        test_process_stop = function (t)
            local r_des, msgid_des = ldsp.tx_duty_cycle_test_stop()
        end
        
    }, 
    [4] = {
        title = "Tx Antenna Gain Test", 
        tips  = "Tx Antenna Gain Test", 
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
            [1] = get_para_func("freq", "Start freq(Hz)"), 
            [2] = function (t) 
                t.band_width = t[2].band_width
            end, 
            [3] = function (t)
                t.power_level = t[3].power_level
            end, 
            [4] = get_para_func("start_delay", "Start delay(s)"), 
            [5] = function (t) 
                t.step_size = t[5].step_size
            end, 
            [6] = get_para_func("step_num", "Step num"), 
            [7] = function (t)
                t.on_time = t[7].on_time
                t.off_time = t[7].off_time
            end, 
        }, 
        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end, 

        [1] = "Start Freq", 
        [2] = {
            title = "Band Width", 
            tips  = "Select Band Width", 
            multi_select_mode = false, 
            action = function (t)
                local bw_g = {0, 1, 2} -- 0:6.25KHz 1:12.5KHz 2:25KHz 
                t.band_width = bw_g[t.select_index]
            end, 
            "6.25 KHz", 
            "12.5 KHz", 
            "25 KHz", 
        }, 
        [3] = {
            title = "Power Level", 
            tips  = "Select Power Level", 
            multi_select_mode = false, 
            action = function (t)
                local power_level_g = {1, 2, 3}
                t.power_level = power_level_g[t.select_index]
            end, 
            "Power Level 1",
            "Power Level 2",
            "Power Level 3",
        }, 
        [4] = "Start delay", 
        [5] = {
            title = "Step size", 
            tips  = "Select Step size", 
            multi_select_mode = false, 
            action = function (t)
                local step_size_g = {0, 1*1000*1000, 2*1000*1000, 5*1000*1000} 
                t.step_size = step_size_g[t.select_index]
            end, 
            "0 Hz", 
            "1 MHz", 
            "2 MHz", 
            "5 MHz", 
        }, 
        [6] = "Step num", 
        [7] = {
            title = "ON/OFF Time Setting", 
            tips  = "Select and input the start/stop time", 
            multi_select_mode = true, 
            action_map = {
                [1] = get_para_func("on_time", "On time"), 
                [2] = get_para_func("off_time", "Off time"), 
            }, 
            action = function (t)
                if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                    t.action_map[t.select_index](t)
                end
            end, 
            "On time(s)", 
            "Off time(s)", 
        }, 
        
        test_process_start = function (t)
            local cr = check_num_parameters(t.freq, t.band_width, t.power_level, t.start_delay, t.step_size, t.step_num, t.on_time, t.off_time)
            if cr.ret then
                local r, errno = ldsp.two_way_transmit_start(t.freq, t.band_width, t.power_level, t.start_delay, t.step_size, t.step_num, t.on_time, t.off_time)
                if not r then
                    slog:err("call ldsp.two_way_transmit_start fail: "..tostring(errno))
                end
            else
                slog:err("call ldsp.two_way_transmit_start parameter error: check "..cr.errno.." "..cr.errmsg)
            end
            
            wait_for_two_way_transmit_stop(t, 1)
            t:test_process_stop()
            t.test_process_start_call = false
            switch_self_refresh(true)
        end, 
        
        test_process_stop = function (t)
            local r_des, msgid_des = ldsp.two_way_transmit_stop()
        end
        
    }, 
}
