-- menu data 

require "ldsp"
require "lnondsp"
require "log"
require "read_attr_file"
require "bluetooth"

local freq_band = {
    VHF = {start=136 * 1000 * 1000, last = 174 * 1000 * 1000}, 
    U3_2ND = {start=763 * 1000 * 1000, last = 890 * 1000 * 1000}, 
}

device_type = read_config_mk_file("/etc/sconfig.mk", "Project")

if "u3" == tostring(device_type) then
    global_freq_band = freq_band.VHF
elseif "u3_2nd" == tostring(device_type) then
    global_freq_band = freq_band.U3_2ND
else
    slog:err("not support device type : "..tostring(device_type))
end

function check_num_range(num, ...)
    if "number" ~= type(num) then
        return false
    end
    local upper, low
    if arg.n == 2 then
        upper = arg[1]
        low = arg[2]
        if upper < low then
            upper, low = low, upper
        end
        
        if (num > upper) or (num < low) then
            return false
        end
    end
    
    return true
end

function check_num_parameters(...)
    slog:notice("check_num_parameters arg.n: "..tostring(arg.n))
    for i=1, arg.n do
        slog:notice("check_num_parameters arg["..i.."]: "..tostring(arg[i]))
        if nil == arg[i] then
            return {ret = false, errno = i, errmsg="arg["..i.."] nil"}
        end
        
        if "number" ~= type(arg[i]) then
            return {ret = false, errno = i, errmsg="arg["..i.."] wrong type, not number"}
        end
    end
    
    return {ret = true}
end

thread_do = function (func)
    local pid = posix.fork()
    
    if pid == 0 then
        if "function" == type(func) then
            func()
        end
        
        posix._exit(0)
    end
    
    return pid
end

function get_para_func(pname, pinfo)
    return function (t)
        local r = get_string_in_window(t[t.select_index])
        if r.ret then
            t[pname] =  tonumber(r.str)
            if nil == t[pname] then
                slog:err("get string in window is not number: "..tostring(r.str))
                t.select_status[t.select_index] = false
                return false
            end
            if not check_num_range(t[pname]) then
                slog:err("enter is not number")
                return false
            end

            t[t.select_index] = pinfo.." "..tostring(r.str)
        else
            slog:err("enter "..r.errmsg)
        end
    end
end 

function init_global_env()
    if not global_env_init then
        ldsp.bit_launch_dsp()
        ldsp.register_callbacks()
        ldsp.start_dsp_service()
        
        lnondsp.register_callbacks()
        lnondsp.bit_gps_thread_create()
        global_env_init = true
    end
end

defunc_enable_gps = function (list_index)
    return function (t)
        local r, msgid
        if t.select_status[list_index] then
            r, msgid = lnondsp.gps_enable()
            t.report[list_index] = {ret=r, errno=msgid}
        else
            r, msgid = lnondsp.gps_disable()
        end
    end
end

defunc_disable_lcd = function (list_index)
    return function (t)
        if t.select_status[list_index] then
            r, msgid = lnondsp.lcd_disable()
            t.report[list_index] = {ret=r, errno=msgid}
        else
            r, msgid = lnondsp.lcd_enable()
        end
    end
end

defunc_lcd_display_static_image = function (list_index)
    return function (t)
        local pic_path = "/root/u3_logo.dat"
        local width = 220
        local height = 176
        local r, msgid
        if t.select_status[list_index] then
            r, msgid = lnondsp.lcd_display_static_image(pic_path, width, height)
            t.report[list_index] = {ret=r, errno=msgid}
        end
    end
end

defunc_lcd_slide_show_test = {
    start = function (list_index)
        return function (t)
            local pic_path = "/usr/slideshow_dat_for_fcc"
            local range = 1  -- The time interval of showing two different images. 
            local r, msgid
            if t.select_status[list_index] then
                r, msgid = lnondsp.lcd_slide_show_test_start(pic_path, range)
                t.report[list_index] = {ret=r, errno=msgid}
            else
                r, msgid = lnondsp.lcd_slide_show_test_stop()
            end
        end
    end, 
    stop = function (list_index)
        return function (t)
            if t.select_status[list_index] then
                lnondsp.lcd_slide_show_test_stop()
            end
        end
    end
}

defunc_led_selftest = {
    start = function (list_index)
        return function (t)
            local r, msgid
            if t.select_status[list_index] then
                r, msgid = lnondsp.led_selftest_start()
                t.report[list_index] = {ret=r, errno=msgid}
            else
                r, msgid = lnondsp.led_selftest_stop()
            end
        end
    end, 
    
    stop = function (list_index)
        return function (t)
            if t.select_status[list_index] then
                lnondsp.led_selftest_stop()
            end
        end
    end
}

defunc_bt_txdata1_transmitter = {
    start = function (list_index) 
        return function (t)
            local r, msgid
            if nil == t.freq or "number" ~= type(t.freq) then
                slog:err("bt_txdata1_transmitter freq error")
                return false
            end
            if nil == t.data_rate or "string" ~= type(t.data_rate) then
                slog:err("bt_txdata1_transmitter data_rate error")
                return false
            end
            if t.select_status[list_index] then
                r, msgid = lnondsp.bt_txdata1_transmitter_start(t.freq, t.data_rate)
                t.report[list_index] = {ret=r, errno=msgid}
            else
                r, msgid = lnondsp.bt_txdata1_transmitter_stop()
            end
        end
    end, 
    
    stop = function (list_index)
        return function (t)
            lnondsp.bt_txdata1_transmitter_stop()
        end
    end
}

defunc_2way_ch1_knob_settings = {
    start = function (list_index) 
        return function (t)
            local tab = {
                freq = global_freq_band.start + 125000, 
                band_width = 1, 
                power = 1, 
                audio_path = 1, 
                squelch = 1, 
                modulation = 1, 
            }
            local r_des, msgid_des
            if t.select_status[list_index] then
                r_des, msgid_des = ldsp.fcc_start(t.freq, t.band_width, t.power, t.audio_path, t.squelch, t.modulation)
                t.report[list_index] = {ret=r, errno=msgid}
            end
        end
    end, 
    
    stop = function (list_index)
        return function (t)
            ldsp.fcc_stop()
        end
    end
}

defunc_calibrate_radio_oscillator_test = function(list_index)
    
    local menu_tab = {
        title = "Cal radiooscillator", 
        tips  = "Enter the afc value to setting, * to save it", 
        multi_select_mode = false, 
    }

    menu_tab.init_env = function (tab) 
        ldsp.calibrate_radio_oscillator_start()
        local r = ldsp.get_original_afc_val()
        if r.ret then
            tab.afc_val = r.afc_val
            slog:err("get_original_afc_val, afc_val "..tostring(tab.afc_val))
        end
        slog:notice("get_original_afc_val, afc_val "..tostring(tab.afc_val))
        tab[1] = "AFC Value: "..tostring(tab.afc_val)
    end
    
    menu_tab.new_main_menu = function(tab)
        local m_sub = create_main_menu(tab)

        m_sub:show()
        m_sub:action()
    end
    
    menu_tab.action_map = {
        [1] = get_para_func("afc_val", "keyin afc_val")
    }
    menu_tab.action = function (tab)
        if ((tab.select_index ~= nil) and ("function" == type(tab.action_map[tab.select_index]))) then
            tab.action_map[tab.select_index](tab)
        end
        
        if nil == tab.afc_val or "number" ~= type(tab.afc_val) then
            slog:err("calibrate_radio_oscillator_test, afc_val "..tostring(tab.afc_val))
            return false
        end
        
        if tab.afc_val > 65535 then
            slog:win("The range the Effective AFC DAC Calibration=(0 to 65535), used max value")
            tab.afc_val = 65535
        end
        ldsp.calibrate_radio_oscillator_set_val(tab.afc_val)
        tab[1] = "AFC Value: "..tostring(menu_tab.afc_val)
    end
    
    menu_tab.test_process_start = function (tab)
        ldsp.save_radio_oscillator_calibration()
        tab.test_process_start_call = false
    end

    return function(t)
        if "nil" == type(t[list_index]) then
            slog:err("calibrate_radio_oscillator_test item nil")
            t[list_index] = "Cal radio oscillator"
        elseif "string" == type(t[list_index]) then
            t[list_index] = menu_tab
            local m = create_main_menu(t[list_index])
            m:show()
            m:action()
        end
    end
end


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
            end, 
            [2] = defunc_enable_bt(2), 
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
        [3] = "Enable GPS", 
        [4] = "Disable LCD", 
        [5] = "Show static image(LCD)", 
        [6] = "Enable slide show", 
        [7] = "Enable LED test", 

        test_process = {
            [1] = function (t)
                local cr = check_num_parameters(t.freq, t.band_width, t.step_size, t.step_num, t.msr_step_num, t.samples, t.delaytime)
                if cr.ret then
                    local r_des, msgid_des = ldsp.start_rx_desense_scan(t.freq, t.band_width, t.step_size, t.step_num, t.msr_step_num, t.samples, t.delaytime)
                else
                    slog:err("parameter error: check "..cr.errno.." "..cr.errmsg)
                end

            end, 
            [2] = function (t)
            
            end, 
            [3] = defunc_enable_gps(3), 
            [4] = defunc_disable_lcd(4), 
            [5] = defunc_lcd_display_static_image(5), 
            [6] = defunc_lcd_slide_show_test.start(6), 
            [7] = defunc_led_selftest.start(7), 
        }, 
        stop_process = {
            [1] = function (t)
                local r_des, msgid_des = ldsp.stop_rx_desense_scan()
            end, 
            [2] = function (t) end, 
            [3] = function (t) end, 
            [4] = function (t) end, 
            [5] = function (t) end, 
            [6] = defunc_lcd_slide_show_test.stop(6), 
            [7] = defunc_led_selftest.stop(7), 

        }, 
        test_process_start = function (t)
            t.report = {}
            for i=1, table.getn(t) do
                if "function" == type(t.test_process[i]) then
                    t.test_process[i](t)
                end
            end
        end, 
        test_process_stop = function (t)
            for i=1, table.getn(t) do
                if "function" == type(t.stop_process[i]) then
                    t.stop_process[i](t)
                end
            end
        end, 
        test_process_report = function (t)
            
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
            end
            
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
                local bw_g = {0, 1, 2} -- 0:6.25KHz 1:12.5KHz 2:25KHz 
                t.band_width = bw_g[t.select_index]
            end, 
            "6.25 KHz", 
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
            [5] = get_para_func("step_size", "Step size"),  
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
        [5] = "Step size", 
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
            local cr = check_num_parameters(t.freq, t.band_width, t.power_level, t.start_delay, t.step_num, t.on_time, t.off_time)
            if cr.ret then
                local r_des, msgid_des = ldsp.two_way_transmit_start(t.freq, t.band_width, t.power_level, t.start_delay, t.step_num, t.on_time, t.off_time)
            else
                slog:err("parameter error: check "..cr.errno.." "..cr.errmsg)
            end
            
        end, 
        
        test_process_stop = function (t)
            local r_des, msgid_des = ldsp.two_way_transmit_stop()
        end
        
    }, 
}

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
        
        if nil ~= g_bt or "table" == type(g_bt.menu_tab) then
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
            local bw_g = {0, 1, 2} -- 0:16.25KHz 1:2.5KHz 2:25KHz 
            t.band_width = bw_g[t.select_index]
        end, 
        "6.25 KHz", 
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
        [8] = defunc_enable_gps(8), 
        [9] = defunc_disable_lcd(9), 
        [10] = defunc_lcd_display_static_image(10), 
        [11] = defunc_lcd_slide_show_test.start(11), 
        [12] = defunc_led_selftest.start(12), 
    }, 
    stop_process = {
        [1] = function (t)
            local r_des, msgid_des = ldsp.fcc_stop()
        end, 
        [7] = function (t) end, 
        [8] = function (t) end, 
        [9] = function (t) end, 
        [10] = function (t) end, 
        [11] = defunc_lcd_slide_show_test.stop(11), 
        [12] = defunc_led_selftest.stop(12), 

    }, 
    test_process_start = function (t)
        if "function" == type(t.test_process[1]) then
            t.test_process[1](t)
        end
        t.report = {}
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

    test_process_report = function (t)
        
    end, 
}

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
        multi_select_mode = false, 

        action = function (t)
            t.freq = t[1].freq
            t.data_rate = t[2].data_rate
        end, 
        [1] =     {
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
        [4] = defunc_enable_gps(4), 
        [5] = defunc_disable_lcd(5), 
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
        [4] = function (t) end, 
        [5] = function (t) end, 
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

GPS_MODE = {
    title = "GPS Test", 
    tips  = "Press * to start. The test will stop automatically", 
    multi_select_mode = true, 
    init_env = function (t)
        init_global_env()
    end, 
    action_map = {
        [1] = function (t) end, 
        [2] = function (t) end, 
        [3] = function (t) end, 
        [4] = defunc_enable_bt(4), 
        [5] = function (t) end, 
        [6] = function (t) end, 
        [7] = function (t) end, 
    }, 
    action = function (t)
        if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
            t.action_map[t.select_index](t)
        end
    end, 
    [1] = {
        --[[ display to user'acquiring GPS signal'.Once acquired display to the user
            the 'latitude and longitude' of the fixes
        --]]
        title = "Functional", 
        tips  = "", 
        multi_select_mode = false, 
        action_map = {
            [1] = function (t) end, 
            [2] = function (t) end, 
            [3] = function (t) end, 
        }, 

        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end, 
        [1] = {}, 
        [2] = {}, 
        [3] = {}, 
    }, 
    [2] = {
        title = "Hardware", 
        tips  = "Hardware test", 
        multi_select_mode = false, 
        action_map = {
            [1] = function (t) end, 
            [2] = function (t) end, 
            [3] = function (t) end, 
            [4] = function (t) end, 
        }, 
        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end, 
        [2] = "SVID to track", 
        [3] = "Tracking time", 
        [4] = "Time between measurements"
    }, 
    [3] = "Enable 2way(ch1 Knob)", 
    [4] = "Enable Bluetooth",  
        --[[ Attempt to pair with a previously connected headset.
            If there is no previous connection, display to the user the Bluetooth device(s)
            available to pair with.
        --]] 
    [5] = "Disable LCD", 
    [6] = "Show static image(LCD)", 
    [7] = "Enable slide show", 
    [8] = "Enable LED test", 

    test_process = {
        [1] = function (t) end, 
        [2] = function (t) end, 
        [3] = defunc_2way_ch1_knob_settings.start(3), 
        [4] = function (t) end, 
        [5] = defunc_disable_lcd(5), 
        [6] = defunc_lcd_display_static_image(6), 
        [7] = defunc_lcd_slide_show_test.start(7), 
        [8] = defunc_led_selftest.start(8), 
    }, 
    stop_process = {
        [1] = function (t) end, 
        [2] = function (t) end, 
        [3] = defunc_2way_ch1_knob_settings.stop(3), 
        [4] = function (t) end, 
        [5] = function (t) end, 
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

Field_MODE = {
    title = "Field test", 
    tips  = "Press * to start and # to end test", 
    multi_select_mode = true, 
    init_env = function (t)
        init_global_env()
    end, 
    action_map = {
        [1] = defunc_calibrate_radio_oscillator_test(1), 
        [2] = function (t) 
            ldsp.restore_default_radio_oscillator_calibration()
            slog:notice("Restore default radio oscillator calibration")
        end, 
        [3] = defunc_enable_bt(3), 
        [4] = function (t) end, 
    }, 
    action = function (t)
        if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
            t.action_map[t.select_index](t)
        end
    end, 
    [1] = "Cal Radio Oscillator", 
    [2] = "Restore Oscillator Cal", 
    [3] = "Find BT Device", 
    [4] = "Enable GPS",  
        --[[ display to user'acquiring GPS signal'.Once acquired display to the user
              the 'latitude and longitude' of the fixes
        --]] 
    
    test_process = {
        [1] = function (t) end, 
        [2] = function (t) end, 
        [3] = function (t) end,  
        [4] = defunc_enable_gps(4), 
    }, 
    stop_process = {
        [1] = function (t) end, 
        [2] = function (t) end, 
        [3] = function (t) end, 
        [4] = function (t) end, 

    }, 
    test_process_start = function (t)
        t.report = {}
        for i=1, 4 do
            if "function" == type(t.test_process[i]) then
                t.test_process[i](t)
            end
        end
    end, 
    test_process_stop = function (t)
        for i=1, 4 do
            if "function" == type(t.stop_process[i]) then
                t.stop_process[i](t)
            end
        end
    end, 

}

BaseBand_MODE = {
    title = "BaseBand Test", 
    tips  = "Select the test item, move and space to select", 
    multi_select_mode = true, 
    init_env = function (t)
        init_global_env()
    end, 
    action_map = {
        [1] = function (t) end, 
        [2] = function (t) end, 
        [3] = function (t) end, 
        [4] = function (t) end, 
        [5] = function (t) end, 
    }, 
    action = function (t)
        if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
            t.action_map[t.select_index](t)
        end
    end, 

    [1] = "Enable GPS", 
    [2] = "Disable LCD", 
    [3]= "Show static image(LCD)", 
    [4]= "Enable slide show", 
    [5]= "Enable LED test", 
}

MODE_SWITCH = {
    title = "Front Panel Mode Ctl", 
    tips  = "select mode, <- to switch and * reboot to switch", 
    multi_select_mode = false, 
    action_map = {
        [1] = function (t)
            global_fpl_mode = t[1].fpl_mode
            t.fpl_mode_name = t[1].fpl_mode_name
        end, 
        [2] = function (t) 
            t.reboot_mode = "app"
        end, 
    }, 
    action = function (t)
        if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
            t.action_map[t.select_index](t)
        end
    end, 
    
    [1] = {
        title = "select to fpl Mode", 
        tips  = "select and reboot", 
        multi_select_mode = false, 
        action_map = {
            [1] = function (t)
                t.fpl_mode = RFT_MODE
                t.fpl_mode_name = "RFT_MODE"
            end, 
            [2] = function (t) 
                t.fpl_mode = FCC_MODE
                t.fpl_mode_name = "FCC_MODE"
            end, 
            [3] = function (t)
                t.fpl_mode = Bluetooth_MODE
                t.fpl_mode_name = "Bluetooth_MODE"
            end, 
            [4] = function (t)
                t.fpl_mode = GPS_MODE
                t.fpl_mode_name = "GPS_MODE"
            end, 
            [5] = function (t)
                t.fpl_mode = Field_MODE
                t.fpl_mode_name = "Field_MODE"
            end, 
            [6] = function (t)
                t.fpl_mode = BaseBand_MODE
                t.fpl_mode_name = "BaseBand_MODE"
            end,
        }, 
        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end, 
        
        [1] = "2Way RF Test", 
        [2] = "FCC Test", 
        [3] = "Bluetooth Test",
        [4] = "GPS Test(nonsupport)",
        [5] = "Field Test",
        --[6] = "BaseBand Test",
    }, 
    [2] = "reboot to app Mode", 
    test_process = {
        [1] = function (t)
            if t.select_status[1] then
                if t.fpl_mode_name then
                    os.execute("echo global_fpl_mode = "..t.fpl_mode_name.." > /userdata/Settings/set_fpl_mode.lua")
                    os.execute("/usr/bin/switch_fpl_mode.sh")
                end
            else
                os.execute("rm -f /userdata/Settings/set_fpl_mode.lua")
            end
        end, 
        [2] = function (t)
            if t.select_status[2] then
                os.execute("rm -f /userdata/Settings/set_fpl_mode.lua")
                os.execute("/sbin/reboot")
            end
        end, 
    }, 
    test_process_start = function (t)
        switch_self_refresh(true)
        for i=1, table.getn(t.test_process) do
            if t.select_status[i] then
                if "function" == type(t.test_process[i]) then
                    t.test_process[i](t)
                end
            end
        end
    end, 
}


table_info = function (t)
    return {
        num = table.getn(t), 
        get_item = function (n)
            if "string" == type(n) then
                for k, v in pairs(t) do
                    if v == n then
                        return k
                    end
                    
                    if k == n then
                        return v
                    end
                end
            elseif "number" == type(n) then
                return t[n]
            else
                slog:err("table_info:get_item() type err: "..type(n))
            end
        end, 
        get_group = function ()
            local num = table.getn(t)
            local gp = {}
            for k, v in ipairs(t) do
                if type(v) == "string" then
                    gp[k] = v
                elseif type(v) == "table" then
                    if type(v.title) == "string" then
                        gp[k] = v.title
                    else
                        slog:err("table_info: "..t.title.." "..k..".title type:"..type(v.title))
                        gp[k] = "unknown item["..k.."]"
                    end
                else
                    slog:err("table_info: "..t.title.." "..k.." type:"..type(v))
                    gp[k] = "unknown item["..k.."]"
                end
            end

            return gp
        end
    }
end
