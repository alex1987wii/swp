-- menu data 

require "ldsp"
require "lnondsp"
require "read_attr_file"
require "bluetooth"

local freq_band = {
    VHF = {start=136 * 1000 * 1000, last = 174 * 1000 * 1000}, 
    U3_2ND = {start=763 * 1000 * 1000, last = 890 * 1000 * 1000}, 
}

device_type = read_attr_file("/proc/sys/kernel/hostname")

if "u3" == device_type then
    global_freq_band = freq_band.VHF
elseif "u3_2nd" == device_type then
    global_freq_band = freq_band.U3_2ND
else
    posix.syslog(posix.LOG_ERR, "not support device type : "..tostring(device_type))
end

global_freq_band = freq_band.U3_2ND

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
    posix.syslog(posix.LOG_ERR, "check_num_parameters arg.n: "..arg.n)
    for i=1, arg.n do
        posix.syslog(posix.LOG_ERR, "check_num_parameters arg["..i.."]: "..tostring(arg[i]))
        if nil == arg[i] then
            return {ret = false, errno = i, errmsg="arg["..i.."] nil"}
        end
        
        if "number" ~= type(arg[i]) then
            return {ret = false, errno = i, errmsg="arg["..i.."] wrong type, not number"}
        end
    end
    
    return {ret = true}
end

thread_do = function(func)
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
    return function(t)
        local r = get_string_in_window(t[t.select_index])
        if r.ret then
            t[pname] =  tonumber(r.str)
            if nil == t[pname] then
                posix.syslog(posix.LOG_ERR, "get string in window is not number: "..r.str)
                t.select_status[t.select_index] = false
                return false
            end
            if not check_num_range(t[pname]) then
                lua_log.i(t[t.select_index], "enter is not number")
                return false
            end

            t[t.select_index] = pinfo.." "..tostring(r.str)
        else
            lua_log.i(t[t.select_index], "enter "..r.errmsg)
        end
    end
end 

function init_global_env()
    if not global_env_init then
        ldsp.bit_launch_dsp()
        ldsp.register_callbacks()
        ldsp.start_dsp_service()
        
        lnondsp.register_callbacks()
        global_env_init = true
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
        init_env = function ()
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
            [2] = function (t)
                if nil == t.bluetooth then
                    t.bluetooth = t[2].bluetooth
                end
            end
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
                [2] = function(t) 
                    t.band_width = t[2].band_width
                end, 
                [3] = function(t) 
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
        [2] = {
            title = "Enable Bluetooth", 
            tips  = "Setting up bluetooth device", 
            multi_select_mode = false, 
            action = function (t)
                
            end, 
        }, 
        [3] = "Enable GPS", 
        [4] = "Disable LCD", 
        [5] = "Show static image(LCD)", 
        [6] = "Enable slide show", 
        [7] = "Enable LED test", 

        test_process = {
            [1] = function(t)
                local cr = check_num_parameters(t.freq, t.band_width, t.step_size, t.step_num, t.msr_step_num, t.samples, t.delaytime)
                if cr.ret then
                    local r_des, msgid_des = ldsp.start_rx_desense_scan(t.freq, t.band_width, t.step_size, t.step_num, t.msr_step_num, t.samples, t.delaytime)
                else
                    note_in_window("parameter error: check "..cr.errno.." "..cr.errmsg)
                end

            end, 
            [2] = function(t)
            
            end, 
            [3] = function(t)
                local r, msgid
                if t.select_status[3] then
                    r, msgid = lnondsp.gps_enable()
                    t.report[3] = {ret=r, errno=msgid}
                else
                    r, msgid = lnondsp.gps_disable()
                end
            end, 
            [4] = function(t)
                local r, msgid
                if t.select_status[4] then
                    r, msgid = lnondsp.lcd_disable()
                    t.report[4] = {ret=r, errno=msgid}
                else
                    r, msgid = lnondsp.lcd_enable()
                end
            end, 
            [5] = function(t)
                local pic_path = "/root/u3_logo.dat"
                local width = 220
                local height = 176
                local r, msgid
                if t.select_status[5] then
                    r, msgid = lnondsp.lcd_display_static_image(pic_path, width, height)
                    t.report[5] = {ret=r, errno=msgid}
                end
            end, 
            [6] = function(t)
                local pic_path = "/usr/slideshow_dat_for_fcc"
                local range = 1  -- The time interval of showing two different images. 
                local r, msgid
                if t.select_status[6] then
                    r, msgid = lnondsp.lcd_slide_show_test_start(pic_path, range)
                    t.report[6] = {ret=r, errno=msgid}
                else
                    r, msgid = lnondsp.lcd_slide_show_test_stop()
                end
            end, 
            [7] = function(t)
                local r, msgid
                if t.select_status[7] then
                    r, msgid = lnondsp.led_selftest_start()
                    t.report[7] = {ret=r, errno=msgid}
                else
                    r, msgid = lnondsp.led_selftest_stop()
                end
            end, 
        }, 
        stop_process = {
            [1] = function(t)
                local r_des, msgid_des = ldsp.stop_rx_desense_scan()
            end, 
            [2] = function(t)
            
            end, 
            [3] = function(t)
                local r, msgid
                if t.select_status[3] then
                    r, msgid = lnondsp.gps_disable()
                end
            end, 
            [4] = function(t)
                local r, msgid
                if t.select_status[4] then
                    r, msgid = lnondsp.lcd_disable()
                end
            end, 
            [5] = function(t)  end, 
            [6] = function(t)
                local r, msgid
                if t.select_status[6] then
                    r, msgid = lnondsp.lcd_slide_show_test_stop()
                end
            end, 
            [7] = function(t)
                local r, msgid
                if t.select_status[7] then
                    r, msgid = lnondsp.led_selftest_stop()
                end
            end, 

        }, 
        test_process_start = function(t)
            t.report = {}
            for i=1, table.getn(t) do
				lua_log.i("test", "tx duty test start "..i)
                if "function" == type(t.test_process[i]) then
                    t.test_process[i](t)
                end
            end
        end, 
        test_process_stop = function(t)
            for i=1, table.getn(t) do
                if "function" == type(t.stop_process[i]) then
                    t.stop_process[i](t)
                end
            end
        end, 
        test_process_report = function(t)
            
        end, 
    }, 
    [2] = {
        title = "Rx Antenna Gain Test", 
        tips  = "* start; up down key move to config", 
        multi_select_mode = true, 
        init_env = function ()
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
            [2] = function(t) 
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
        
        test_process_start = function(t)
            local cr = check_num_parameters(t.freq, t.band_width, t.step_size, t.step_num, t.msr_step_num, t.samples, t.delaytime)
            if cr.ret then
                local r_des, msgid_des = ldsp.start_rx_desense_scan(t.freq, t.band_width, t.step_size, t.step_num, t.msr_step_num, t.samples, t.delaytime)
            else
                note_in_window("parameter error: check "..cr.errno.." "..cr.errmsg)
            end
            
        end, 
        
        test_process_stop = function(t)
            local r_des, msgid_des = ldsp.stop_rx_desense_scan()
        end
    }, 
    [3] = {
        title = "Tx with a duty cycle", 
        tips  = "Tx only with a settable duty cycle", 
        multi_select_mode = true, 
        init_env = function ()
            init_global_env()
        end, 
        new_main_menu = function (t)
            local m_sub = create_main_menu(t)
            m_sub:show()
            m_sub:action()
        end, 
        action_map = {
            [1] = function(t)
                t.freq = t[1].freq
            end, 
            [2] = function(t) 
                t.band_width = t[2].band_width
            end, 
            [3] = function(t)
                t.power = t[3].power
            end, 
            [4] = function(t)
                t.audio_path = t[4].audio_path
            end, 
            [5] = function(t)
                t.modulation = t[5].modulation
            end, 
            [6] = function(t)
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
                [1] = function(t)
                    t.freq =  global_freq_band.start + 125 * 1000
                end, 
                [2] = function(t)
                    t.freq =  (global_freq_band.start + global_freq_band.last) / 2 + 125 * 1000
                end, 
                [3] = function(t)
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
        
        test_process_start = function(t)
            local cr = check_num_parameters(t.freq, t.band_width, t.power, t.audio_path, t.modulation, t.trans_on_time, t.trans_off_time)
            if cr.ret then
                posix.syslog(posix.LOG_ERR, "before call tx_duty_cycle_test_start ")
                local r_des, msgid_des = ldsp.tx_duty_cycle_test_start(t.freq, t.band_width, t.power, t.audio_path, t.modulation, t.trans_on_time, t.trans_off_time)
                posix.syslog(posix.LOG_ERR, "end of call tx_duty_cycle_test_start ")
            else
                note_in_window("parameter error: check "..cr.errno.." "..cr.errmsg)
            end
            
        end, 
        
        test_process_stop = function(t)
                posix.syslog(posix.LOG_ERR, "before call tx_duty_cycle_test_stop ")
            local r_des, msgid_des = ldsp.tx_duty_cycle_test_stop()
                posix.syslog(posix.LOG_ERR, "end of call tx_duty_cycle_test_stop ")
        end
        
    }, 
    [4] = {
        title = "Tx Antenna Gain Test", 
        tips  = "Tx Antenna Gain Test", 
        multi_select_mode = true, 
        init_env = function ()
            init_global_env()
        end, 
        new_main_menu = function (t)
            local m_sub = create_main_menu(t)
            m_sub:show()
            m_sub:action()
        end, 
        action_map = {
            [1] = get_para_func("freq", "Start freq(Hz)"), 
            [2] = function(t) 
                t.band_width = t[2].band_width
            end, 
            [3] = function(t)
                t.power_level = t[3].power_level
            end, 
            [4] = get_para_func("start_delay", "Start delay(s)"), 
            [5] = get_para_func("step_size", "Step size"),  
            [6] = get_para_func("step_num", "Step num"), 
            [7] = function(t)
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
        
        test_process_start = function(t)
            local cr = check_num_parameters(t.freq, t.band_width, t.power_level, t.start_delay, t.step_num, t.on_time, t.off_time)
            if cr.ret then
                posix.syslog(posix.LOG_ERR, "before call two_way_transmit_start ")
                local r_des, msgid_des = ldsp.two_way_transmit_start(t.freq, t.band_width, t.power_level, t.start_delay, t.step_num, t.on_time, t.off_time)
                posix.syslog(posix.LOG_ERR, "end of call two_way_transmit_start ")
            else
                posix.syslog(posix.LOG_ERR, "before note_in_window ")
                note_in_window("parameter error: check "..cr.errno.." "..cr.errmsg)
                posix.syslog(posix.LOG_ERR, "end of call note_in_window ")
            end
            
        end, 
        
        test_process_stop = function(t)
            posix.syslog(posix.LOG_ERR, "before call two_way_transmit_stop ")
            local r_des, msgid_des = ldsp.two_way_transmit_stop()
            posix.syslog(posix.LOG_ERR, "end of call two_way_transmit_stop ")
        end
        
    }, 
}

FCC_MODE = {
    title = "Front Panel", 
    tips  = "Select the test item, move and space to select", 
    multi_select_mode = true, 
    init_env = function ()
        init_global_env()
    end, 

    action_map = {
        [1] = function(t)
            t.freq = t[1].freq
        end, 
        [2] = function(t) 
            t.band_width = t[2].band_width
        end, 
        [3] = function(t)
            t.power = t[3].power
        end, 
        [4] = function(t)
            t.audio_path = t[4].audio_path
        end, 
        [5] = function(t)
            t.squelch = t[5].squelch
        end, 
        [6] = function(t)
            t.modulation = t[6].modulation
        end, 
        [7] = function(t) end, 
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
            [1] = function(t)
                t.freq =  global_freq_band.start + 125 * 1000
            end, 
            [2] = function(t)
                t.freq =  (global_freq_band.start + global_freq_band.last) / 2 + 125 * 1000
            end, 
            [3] = function(t)
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
        "BlueTooth (attempt to auto pair)", 
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
            [1] = function(t)
                t.modulation = 1
            end, 
            [2] = function(t)
                t.modulation = t[2].analog
            end, 
            [3] = function(t)
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
    [7] = {
        title = "Enable Bluetooth", 
        tips  = "Setting up bluetooth device", 
        multi_select_mode = false, 
        action = function (t)
            
        end, 
    }, 
    [8] = "Enable GPS", 
    [9] = "Disable LCD", 
    [10]= "Show static image(LCD)", 
    [11]= "Enable slide show", 
    [12]= "Enable LED test", 

    test_process = {
        [1] = function(t)
            local cr = check_num_parameters(t.freq, t.band_width, t.power, t.audio_path, t.squelch, t.modulation)
            if cr.ret then
                local r_des, msgid_des = ldsp.fcc_start(t.freq, t.band_width, t.power, t.audio_path, t.squelch, t.modulation)
            else
                note_in_window("parameter error: check "..cr.errno.." "..cr.errmsg)
            end

        end, 
        [7] = function(t)
        
        end, 
        [8] = function(t)
            local r, msgid
            if t.select_status[8] then
                r, msgid = lnondsp.gps_enable()
                t.report[8] = {ret=r, errno=msgid}
            else
                r, msgid = lnondsp.gps_disable()
            end
        end, 
        [9] = function(t)
            local r, msgid
            if t.select_status[9] then
                r, msgid = lnondsp.lcd_disable()
                t.report[9] = {ret=r, errno=msgid}
            else
                r, msgid = lnondsp.lcd_enable()
            end
        end, 
        [10] = function(t)
            local pic_path = "/root/u3_logo.dat"
            local width = 220
            local height = 176
            local r, msgid
            if t.select_status[10] then
                r, msgid = lnondsp.lcd_display_static_image(pic_path, width, height)
                t.report[10] = {ret=r, errno=msgid}
            end
        end, 
        [11] = function(t)
            local pic_path = "/usr/slideshow_dat_for_fcc"
            local range = 1  -- The time interval of showing two different images. 
            local r, msgid
            if t.select_status[11] then
                r, msgid = lnondsp.lcd_slide_show_test_start(pic_path, range)
                t.report[11] = {ret=r, errno=msgid}
            else
                r, msgid = lnondsp.lcd_slide_show_test_stop()
            end
        end, 
        [12] = function(t)
            local r, msgid
            if t.select_status[12] then
                r, msgid = lnondsp.led_selftest_start()
                t.report[12] = {ret=r, errno=msgid}
            else
                r, msgid = lnondsp.led_selftest_stop()
            end
        end, 
    }, 
    stop_process = {
        [1] = function(t)
            local r_des, msgid_des = ldsp.fcc_stop()
        end, 
        [7] = function(t)
        
        end, 
        [8] = function(t)
            local r, msgid
            if t.select_status[8] then
                r, msgid = lnondsp.gps_disable()
            end
        end, 
        [9] = function(t)
            local r, msgid
            if t.select_status[9] then
                r, msgid = lnondsp.lcd_disable()
            end
        end, 
        [10] = function(t)  end, 
        [11] = function(t)
            local r, msgid
            if t.select_status[11] then
                r, msgid = lnondsp.lcd_slide_show_test_stop()
            end
        end, 
        [12] = function(t)
            local r, msgid
            if t.select_status[12] then
                r, msgid = lnondsp.led_selftest_stop()
            end
        end, 

    }, 
    test_process_start = function(t)
        if "function" == type(t.test_process[1]) then
            t.test_process[1](t)
        end
        t.report = {}
        for i=7, 12 do
            lua_log.i("test", "tx duty test start "..i)
            if "function" == type(t.test_process[i]) then
                t.test_process[i](t)
            end
        end
    end, 
    test_process_stop = function(t)
        if "function" == type(t.stop_process[1]) then
            t.stop_process[1](t)
        end
        for i=7, 12 do
            if "function" == type(t.stop_process[i]) then
                t.stop_process[i](t)
            end
        end
    end, 
    test_process_report = function(t)
        
    end, 
}

Bluetooth_MODE = {
    title = "Bluetooth", 
    tips  = "Press * to start and # to end test", 
    multi_select_mode = true, 
    init_env = function ()
        init_global_env()
    end, 
    action_map = {
        [1] = function(t)

        end, 
        [2] = function(t) 

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
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
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
    [3] = "Enable 2way(ch1 Knob settings)", 
    [4] = "Enable GPS",  
        --[[ display to user'acquiring GPS signal'.Once acquired display to the user
              the 'latitude and longitude' of the fixes
        --]] 
    [5] = "Disable LCD", 
    [6] = "Show static image(LCD)", 
    [7] = "Enable slide show", 
    [8] = "Enable LED test", 
}

GPS_MODE = {
    title = "GPS Test", 
    tips  = "Press * to start. The test will stop automatically", 
    multi_select_mode = true, 
    init_env = function ()
        init_global_env()
    end, 
    action_map = {
        [1] = function(t)

        end, 
        [2] = function(t) 

        end, 
        [3] = function(t)

        end, 
        [4] = function(t)

        end, 
        [5] = function(t)

        end, 
        [6] = function(t)

        end, 
        [7] = function(t) end, 
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

        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end, 

    }, 
    [2] = {
        title = "Hardware", 
        tips  = "Hardware test", 
        multi_select_mode = false, 

        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end, 
        [1] = "Number of measurements", 
        [2] = "SVID to track", 
        [3] = "Tracking time", 
        [4] = "Time between measurements"
    }, 
    [3] = "Enable 2way(ch1 Knob settings)", 
    [4] = "Enable Bluetooth",  
        --[[ Attempt to pair with a previously connected headset.
            If there is no previous connection, display to the user the Bluetooth device(s)
            available to pair with.
        --]] 
    [5] = "Disable LCD", 
    [6] = "Show static image(LCD)", 
    [7] = "Enable slide show", 
    [8] = "Enable LED test", 
}

BaseBand_MODE = {
    title = "BaseBand Test", 
    tips  = "Select the test item, move and space to select", 
    multi_select_mode = true, 
    init_env = function ()
        init_global_env()
    end, 
    action_map = {
        [1] = function(t)
            
        end, 
        [2] = function(t) 
            
        end, 
        [3] = function(t)
            
        end, 
        [4] = function(t)
            
        end, 
        [5] = function(t)
            
        end, 

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


Field_MODE = {
    title = "Bluetooth", 
    tips  = "Press * to start and # to end test", 
    multi_select_mode = true, 
    init_env = function ()
        init_global_env()
    end, 
    action_map = {
        [1] = function(t)

        end, 
        [2] = function(t) 

        end, 
        [3] = function(t)

        end, 
        [4] = function(t)

        end, 
    }, 
    action = function (t)
        if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
            t.action_map[t.select_index](t)
        end
    end, 
    [1] = "Calibrate Radio Oscillator", 
    [2] = "Restor default Radio Oscillator Calibration", 
    [3] = {
        title = "Find BT Device", 
        tips  = "Find BT Device", 
        multi_select_mode = false, 

        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end, 

    }, 
    [4] = "Enable GPS",  
        --[[ display to user'acquiring GPS signal'.Once acquired display to the user
              the 'latitude and longitude' of the fixes
        --]] 
}


MODE_SWITCH = {
    title = "Front Panel Mode Ctl", 
    tips  = "select mode, and * to switch", 
    multi_select_mode = false, 
    action_map = {
        [1] = function(t)
            global_fpl_mode = t[1].fpl_mode
            t.fpl_mode_name = t[1].fpl_mode_name
        end, 
        [2] = function(t) 
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
            [1] = function(t)
                t.fpl_mode = RFT_MODE
                t.fpl_mode_name = "RFT_MODE"
            end, 
            [2] = function(t) 
                t.fpl_mode = FCC_MODE
                t.fpl_mode_name = "FCC_MODE"
            end, 
            [3] = function(t)
                t.fpl_mode = Bluetooth_MODE
                t.fpl_mode_name = "Bluetooth_MODE"
            end, 
            [4] = function(t)
                t.fpl_mode = GPS_MODE
                t.fpl_mode_name = "GPS_MODE"
            end, 
            [5] = function(t)
                t.fpl_mode = Field_MODE
                t.fpl_mode_name = "Field_MODE"
            end, 
            [6] = function(t)
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
        [4] = "GPS Test",
        [5] = "Field Test",
        [6] = "BaseBand Test",
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
    test_process_start = function(t)
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


table_info = function(t)
    return {
        num = table.getn(t), 
        get_item = function(n)
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
                lua_log.e("table_info", "get_item() type err: "..type(n))
            end
        end, 
        get_group = function()
            local num = table.getn(t)
            local gp = {}
            for k, v in ipairs(t) do
                if type(v) == "string" then
                    gp[k] = v
                elseif type(v) == "table" then
                    if type(v.title) == "string" then
                        gp[k] = v.title
                    else
                        lua_log.e("table_info", t.title.." "..k..".title type:"..type(v.title))
                        gp[k] = "unknown item["..k.."]"
                    end
                else
                    lua_log.e("table_info", t.title.." "..k.." type:"..type(v))
                    gp[k] = "unknown item["..k.."]"
                end
            end

            return gp
        end
    }
end
