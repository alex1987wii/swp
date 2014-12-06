-- menu data 

require "ldsp"
require "lnondsp"

local freq_band = {
    VHF = {start=136 * 1000 * 100, last = 174 * 1000 * 1000}, 
    UHF = {start=136 * 1000 * 100, last = 174 * 1000 * 1000},
}

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
    for i=1, arg.n do
        if nil == arg[i] then
            return {ret = false, errno = i, errmsg="arg["..i.."] nil"}
        end
        
        if "number" ~= type(arg[i]) then
            return {ret = false, errno = i, errmsg="arg["..i.."] wrong type, not number"}
        end
    end
    
    return {ret = true}
end

switch_self_refresh = function(flag)
    if "boolean" ~= type(flag) then
        posix.syslog(posix.LOG_ERR, "switch_self_refresh: flag type error")
        return false
    end
    if flag then
        os.execute("echo 1 > /sys/devices/platform/ad6900-lcd/self_refresh")
    else
        os.execute("echo 0 > /sys/devices/platform/ad6900-lcd/self_refresh")
    end
    
    return true
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

front_panel_data = {
    RFT = {
        title = "2Way RF Test", 
        tips  = "select and test", 
        multi_select_mode = false, 
        action = function (t)
        
        end, 

        [1] = {
            title = "Rx Desense Test", 
            tips  = "Rx Desense Test", 
            multi_select_mode = true, 
            new_main_menu = function (t)
                local m_sub = create_main_menu(t)
                m_sub:show()
                m_sub:action()
            end, 
            action_map = {
                [2] = function(t)
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
                new_main_menu = function (t)
                    local m_sub = create_main_menu(t)
                    m_sub:show()
                    m_sub:action()
                end, 
                action_map = {
                    [1] = function(t)
                        local r = get_string_in_window(t[t.select_index])
                        if r.ret then
                            t.freq =  tonumber(r.str)
                            if nil == t.freq then
                                posix.syslog(posix.LOG_ERR, "get string in window is not number: "..r.str)
                                t.select_status[t.select_index] = false
                                return false
                            end
                            if not check_num_range(t.freq) then
                                lua_log.i(t[t.select_index], "enter is not number")
                                return false
                            end
                            t[t.select_index] = "Freq(Hz) "..tostring(r.str)
                        else
                            lua_log.i(t[t.select_index], "enter "..r.errmsg)
                        end
                    end, 
                    [2] = function(t) 
                        t.band_width = t[2].band_width
                    end, 
                    [3] = function(t) 
                        t.step_size = t[3].step_size
                    end, 
                    [4] = function(t)
                        local r = get_string_in_window(t[t.select_index])
                        if r.ret then
                            t.step_num =  tonumber(r.str)
                            if nil == t.step_num then
                                posix.syslog(posix.LOG_ERR, "get string in window is not number: "..r.str)
                                t.select_status[t.select_index] = false
                                return false
                            end
                            if not check_num_range(t.step_num, 0, 1500) then
                                lua_log.i(t[t.select_index], "enter "..t.step_num.." is not 0~1500")
                                return false
                            end
                            t[t.select_index] = "Step Num(0~1500) "..r.str
                        else
                            lua_log.i(t[t.select_index], "enter "..r.errmsg)
                        end
                    end, 
                    [5] = function(t)
                        local r = get_string_in_window(t[t.select_index])
                        if r.ret then
                            t.msr_step_num =  tonumber(r.str)
                            if nil == t.msr_step_num then
                                posix.syslog(posix.LOG_ERR, "get string in window is not number: "..r.str)
                                t.select_status[t.select_index] = false
                                return false
                            end
                            if not check_num_range(t.msr_step_num, 0, 50) then
                                lua_log.i(t[t.select_index], "enter "..t.msr_step_num.." is not 0~50")
                                return false
                            end
                            t[t.select_index] = "msr_step_num(0~50) "..r.str
                        else
                            lua_log.i(t[t.select_index], "enter "..r.errmsg)
                        end
                    end, 
                    [6] = function(t)
                        local r = get_string_in_window(t[t.select_index])
                        if r.ret then
                            t.samples =  tonumber(r.str)
                            if nil == t.simples then
                                posix.syslog(posix.LOG_ERR, "get string in window is not number: "..r.str)
                                t.select_status[t.select_index] = false
                                return false
                            end
                            if not check_num_range(t.samples, 10, 5000) then
                                lua_log.i(t[t.select_index], "enter "..t.samples.." is not 10~5000")
                                return false
                            end
                            t[t.select_index] = "samples(10~5000) "..r.str
                        else
                            lua_log.i(t[t.select_index], "enter "..r.errmsg)
                        end
                    end, 
                    [7] = function(t)
                        local r = get_string_in_window(t[t.select_index])
                        if r.ret then
                            t.delaytime =  tonumber(r.str)
                            if nil == t.delaytime then
                                posix.syslog(posix.LOG_ERR, "get string in window is not number: "..r.str)
                                t.select_status[t.select_index] = false
                                return false
                            end
                            if not check_num_range(t.delaytime, 0, 100) then
                                lua_log.i(t[t.select_index], "enter "..t.delaytime.." is not 0~100")
                                return false
                            end
                            t[t.select_index] = "delaytime(0~100s) "..r.str
                        else
                            lua_log.i(t[t.select_index], "enter "..r.errmsg)
                        end
                    end, 
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
                action = function ()
                    
                end, 
            }, 
            [3] = "Enable GPS", 
            [4] = "Enable LCD", 
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
                        r, msgid = lnondsp.lcd_enable()
                        t.report[4] = {ret=r, errno=msgid}
                    else
                        r, msgid = lnondsp.lcd_disable()
                    end
                end, 
                [5] = function(t)
                    local pic_path = "/root/u4_logo.dat"
                    local width = 270
                    local height = 220
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
                for i=1, #t do
                    if "function" == type(t.test_process[i]) then
                        t.test_process[i](t)
                    end
                end
            end, 
            test_process_stop = function(t)
                for i=1, #t do
                    if "function" == type(t.test_process[i]) then
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
            new_main_menu = function (t)
                local m_sub = create_main_menu(t)
                m_sub:show()
                m_sub:action()
            end, 
            step_num = 1,  
            step_size = 0, 
            action_map = {
                [1] = function(t)
                    local r = get_string_in_window(t[t.select_index])
                    if r.ret then
                        t.freq =  tonumber(r.str)
                        if nil == t.freq then
                            posix.syslog(posix.LOG_ERR, "get string in window is not number: "..r.str)
                            t.select_status[t.select_index] = false
                            return false
                        end
                        
                        if not check_num_range(t.freq) then
                            lua_log.i(t[t.select_index], "enter is not number")
                            return false
                        end
                        t[t.select_index] = "Start freq(Hz) "..r.str
                    else
                        lua_log.i(t[t.select_index], "enter "..r.errmsg)
                    end
                end, 
                [2] = function(t) 
                    t.band_width = t[2].band_width
                end, 
                [3] = function(t)
                    local r = get_string_in_window(t[t.select_index])
                    if r.ret then
                        t.msr_step_num =  tonumber(r.str)
                        if nil == t.msr_step_num then
                            posix.syslog(posix.LOG_ERR, "get string in window is not number: "..r.str)
                            t.select_status[t.select_index] = false
                            return false
                        end
                        if not check_num_range(t.msr_step_num, 0, 50) then
                            lua_log.i(t[t.select_index], "enter "..t.msr_step_num.." is not 0~50")
                            return false
                        end
                        t[t.select_index] = "msr_step_num(0~50) "..r.str
                    else
                        lua_log.i(t[t.select_index], "enter "..r.errmsg)
                    end
                end, 
                [4] = function(t)
                    local r = get_string_in_window(t[t.select_index])
                    if r.ret then
                        t.samples =  tonumber(r.str)
                        if nil == t.samples then
                            posix.syslog(posix.LOG_ERR, "get string in window is not number: "..r.str)
                            t.select_status[t.select_index] = false
                            return false
                        end
                        if not check_num_range(t.samples, 10, 5000) then
                            lua_log.i(t[t.select_index], "enter "..t.samples.." is not 10~5000")
                            return false
                        end
                        t[t.select_index] = "samples(10~5000) "..r.str
                    else
                        lua_log.i(t[t.select_index], "enter "..r.errmsg)
                    end
                end, 
                [5] = function(t)
                    local r = get_string_in_window(t[t.select_index])
                    if r.ret then
                        t.delaytime =  tonumber(r.str)
                        if nil == t.delaytime then
                            posix.syslog(posix.LOG_ERR, "get string in window is not number: "..r.str)
                            t.select_status[t.select_index] = false
                            return false
                        end
                        if not check_num_range(t.delaytime, 0, 100) then
                            lua_log.i(t[t.select_index], "enter "..t.delaytime.." is not 0~100")
                            return false
                        end
                        t[t.select_index] = "delaytime(0~100s) "..r.str
                    else
                        lua_log.i(t[t.select_index], "enter "..r.errmsg)
                    end
                end, 
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
                    t.modulation = t[4].modulation
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
                        t.freq =  136125 * 1000
                    end, 
                    [2] = function(t)
                        t.freq =  155125 * 1000
                    end, 
                    [3] = function(t)
                        t.freq =  173125 * 1000
                    end, 
                    [4] = function(t)
                        local r = get_string_in_window(t[t.select_index])
                        if r.ret then
                            t.freq =  tonumber(r.str)
                            if nil == t.freq then
                                posix.syslog(posix.LOG_ERR, "get string in window is not number: "..r.str)
                                t.select_status[t.select_index] = false
                                return false
                            end
                            
                            if not check_num_range(t.freq) then
                                lua_log.i(t[t.select_index], "enter is not number")
                                return false
                            end
                            t[t.select_index] = r.str.." (Hz)"
                        else
                            lua_log.i(t[t.select_index], "Enter "..r.errmsg)
                        end
                    end, 
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
                action = function ()
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
                action = function ()
                    local audio_path = {1, 2}
                end, 
                "Internal mic", 
                "External mic", 
            }, 
            [5] = {
                title = "Modulation", 
                tips  = "Select Modulation", 
                multi_select_mode = false, 
                action = function ()
                    local modulation = {1, 2, 3, 4, 5, 8}
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
                    [1] = function(t)
                        local r = get_string_in_window(t[t.select_index])
                        if r.ret then
                            t.trans_on_time =  tonumber(r.str)
                            if nil == t.trans_on_time then
                                posix.syslog(posix.LOG_ERR, "get string in window is not number: "..r.str)
                                t.select_status[t.select_index] = false
                                return false
                            end
                            if not check_num_range(t.trans_on_time, 0, 100) then
                                lua_log.i(t[t.select_index], "enter "..t.trans_on_time.." is not 0~100")
                                return false
                            end
                            t[t.select_index] = "Tx on time "..r.str
                        else
                            lua_log.i(t[t.select_index], "enter "..r.errmsg)
                        end
                    end, 
                    [2] = function(t)
                        local r = get_string_in_window(t[t.select_index])
                        if r.ret then
                            t.trans_off_time =  tonumber(r.str)
                            if nil == t.trans_off_time then
                                posix.syslog(posix.LOG_ERR, "get string in window is not number: "..r.str)
                                t.select_status[t.select_index] = false
                                return false
                            end
                            if not check_num_range(t.trans_off_time, 0, 100) then
                                lua_log.i(t[t.select_index], "enter "..t.trans_off_time.." is not 0~100")
                                return false
                            end
                            t[t.select_index] = "Tx off time "..r.str
                        else
                            lua_log.i(t[t.select_index], "enter "..r.errmsg)
                        end
                    end, 
                }, 
                action = function ()
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
                    local r_des, msgid_des = ldsp.tx_duty_cycle_test_start(t.freq, t.band_width, t.power, t.audio_path, t.modulation, t.trans_on_time, t.trans_off_time)
                else
                    note_in_window("parameter error: check "..cr.errno.." "..cr.errmsg)
                end
                
            end, 
            
            test_process_stop = function(t)
                local r_des, msgid_des = ldsp.tx_duty_cycle_test_stop()
            end
            
        }, 
        [4] = {
            title = "Tx Antenna Gain Test", 
            tips  = "Tx Antenna Gain Test", 
            multi_select_mode = true, 
            new_main_menu = function (t)
                local m_sub = create_main_menu(t)
                m_sub:show()
                m_sub:action()
            end, 
            action_map = {
                [1] = function(t)
                    local r = get_string_in_window(t[t.select_index])
                    if r.ret then
                        t.freq =  tonumber(r.str)
                        if nil == t.freq then
                            posix.syslog(posix.LOG_ERR, "get string in window is not number: "..r.str)
                            t.select_status[t.select_index] = false
                            return false
                        end
                        if not check_num_range(t.freq) then
                            lua_log.i(t[t.select_index], "enter is not number")
                            return false
                        end
                        t[t.select_index] = "Start freq(Hz) "..tostring(r.str)
                    else
                        lua_log.i(t[t.select_index], "enter "..r.errmsg)
                    end
                end, 
                [2] = function(t) 
                    t.band_width = t[2].band_width
                end, 
                [3] = function(t)
                    t.power_level = t[3].power_level
                end, 
                [4] = function(t)
                    local r = get_string_in_window(t[t.select_index])
                    if r.ret then
                        t.start_delay =  tonumber(r.str)
                        if nil == t.start_delay then
                            posix.syslog(posix.LOG_ERR, "get string in window is not number: "..r.str)
                            t.select_status[t.select_index] = false
                            return false
                        end
                        if not check_num_range(t.start_delay) then
                            lua_log.i(t[t.select_index], "enter is not number")
                            return false
                        end
                        t[t.select_index] = "Start delay(s) "..tostring(r.str)
                    else
                        lua_log.i(t[t.select_index], "enter "..r.errmsg)
                    end
                end, 
                [5] = function(t)
                    local r = get_string_in_window(t[t.select_index])
                    if r.ret then
                        t.step_size =  tonumber(r.str)
                        if nil == t.step_size then
                            posix.syslog(posix.LOG_ERR, "get string in window is not number: "..r.str)
                            t.select_status[t.select_index] = false
                            return false
                        end
                        if not check_num_range(t.step_size) then
                            lua_log.i(t[t.select_index], "enter is not number")
                            return false
                        end
                        t[t.select_index] = "Step size "..tostring(r.str)
                    else
                        lua_log.i(t[t.select_index], "enter "..r.errmsg)
                    end
                end, 
                [6] = function(t)
                    local r = get_string_in_window(t[t.select_index])
                    if r.ret then
                        t.step_num =  tonumber(r.str)
                        if nil == t.step_num then
                            posix.syslog(posix.LOG_ERR, "get string in window is not number: "..r.str)
                            t.select_status[t.select_index] = false
                            return false
                        end
                        if not check_num_range(t.step_num) then
                            lua_log.i(t[t.select_index], "enter is not number")
                            return false
                        end
                        t[t.select_index] = "Step num "..tostring(r.str)
                    else
                        lua_log.i(t[t.select_index], "enter "..r.errmsg)
                    end
                end, 
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
                action = function ()
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
                    [1] = function(t)
                        local r = get_string_in_window(t[t.select_index])
                        if r.ret then
                            t.on_time =  tonumber(r.str)
                            if nil == t.on_time then
                                posix.syslog(posix.LOG_ERR, "get string in window is not number: "..r.str)
                                t.select_status[t.select_index] = false
                                return false
                            end
                            if not check_num_range(t.on_time, 0, 100) then
                                lua_log.i(t[t.select_index], "enter "..t.on_time.." is not 0~100")
                                return false
                            end
                            t[t.select_index] = "On time "..r.str
                        else
                            lua_log.i(t[t.select_index], "enter "..r.errmsg)
                        end
                    end, 
                    [2] = function(t)
                        local r = get_string_in_window(t[t.select_index])
                        if r.ret then
                            t.off_time =  tonumber(r.str)
                            if nil == t.off_time then
                                posix.syslog(posix.LOG_ERR, "get string in window is not number: "..r.str)
                                t.select_status[t.select_index] = false
                                return false
                            end
                            if not check_num_range(t.off_time, 0, 100) then
                                lua_log.i(t[t.select_index], "enter "..t.off_time.." is not 0~100")
                                return false
                            end
                            t[t.select_index] = "Off time "..r.str
                        else
                            lua_log.i(t[t.select_index], "enter "..r.errmsg)
                        end
                    end, 
                }, 
                action = function ()
                    if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                        t.action_map[t.select_index](t)
                    end
                end, 
                "Tx on time(s)", 
                "Tx off time(s)", 
            }, 
            
            test_process_start = function(t)
                local cr = check_num_parameters(t.freq, t.band_width, t.power_level, t.step_delay, t.step_num, t.on_time, t.off_time)
                if cr.ret then
                    local r_des, msgid_des = ldsp.two_way_transmit_start(t.freq, t.band_width, t.power_level, t.step_delay, t.step_num, t.on_time, t.off_time)
                else
                    note_in_window("parameter error: check "..cr.errno.." "..cr.errmsg)
                end
                
            end, 
            
            test_process_stop = function(t)
                local r_des, msgid_des = ldsp.two_way_transmit_stop()
            end
            
        }, 
    }, 

    FCC = {
        title = "Front Panel", 
        tips  = "Select the test item, move and space to select", 
        multi_select_mode = true, 
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
                t.mod_mode = t[6].mod_mode
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
                    t.freq =  136125 * 1000
                end, 
                [2] = function(t)
                    t.freq =  155125 * 1000
                end, 
                [3] = function(t)
                    t.freq =  173125 * 1000
                end, 
                [4] = function(t)
                    local r = get_string_in_window(t[t.select_index])
                    if r.ret then
                        t.freq =  tonumber(r.str)
                        if nil == t.freq then
                            posix.syslog(posix.LOG_ERR, "get string in window is not number: "..r.str)
                            t.select_status[t.select_index] = false
                            return false
                        end
                        
                        if not check_num_range(t.freq) then
                            lua_log.i(t[t.select_index], "enter is not number")
                            return false
                        end
                        t[t.select_index] = r.str.." (Hz)"
                    else
                        lua_log.i(t[t.select_index], "Enter "..r.errmsg)
                    end
                end, 
            }, 
            action = function (t)
                if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                    t.action_map[t.select_index](t)
                end
            end, 
            "136.125MHz", 
            "155.125MHz", 
            "173.125MHz", 
            "Enter freq (Hz)", 
        }, 
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
        [3] = {
            title = "Power", 
            tips  = "Select Power", 
            multi_select_mode = false, 
            action = function (t)
                local powers = {1, 2, 3, 5}
                t.power = powers[t.select_index]
            end, 
            "1 Watt", 
            "2 Watt", 
            "3 Watt",
            "5 Watt",
        }, 
        [4] = {
            title = "Audio Path", 
            tips  = "Select Audio Path", 
            multi_select_mode = false, 
            action = function (t)
                local audio_path_g = {0, 1, 2}  -- 0:internal speaker/mic, 1:external speaker/mic, 2:bluetooth 
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
                [1] = function(t)
                    t.modulation = 0
                end, 
                [2] = function(t)
                    t.modulation = 1
                    t.mod_mode = t[2].analog
                end, 
                [3] = function(t)
                    t.modulation = 2
                    t.mod_mode = t[3].digital
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
                action = function ()
                    local analog_g = {0, 1, 2, 3}
                    t.analog = analog_t[t.select_index]
                end, 
                "CTCSS (Tone = 250.3 Hz)", 
                "CDCSS (Code = 532)", 
                "MDC1200", 
                "none", 
            }, 
            [3] = {
                title = "Digital", 
                tips  = "Select Digital", 
                multi_select_mode = false, 
                action = function ()
                    local digital_g = {0, 1, 2, 3, 4, 5, 6}
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
            action = function ()
                
            end, 
        }, 
        [8] = "Enable GPS", 
        [9] = "Enable LCD", 
        [10]= "Show static image(LCD)", 
        [11]= "Enable slide show", 
        [12]= "Enable LED test", 
    }, 

    Bluetooth = {
        title = "Bluetooth", 
        tips  = "Select the test item, move and space to select", 
        multi_select_mode = true, 
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
                t.mod_mode = t[6].mod_mode
            end, 
            [7] = function(t) end, 
        }, 
        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end, 
        [1] = {
            title = "Find BT Device", 
            tips  = "Find BT Device", 
            multi_select_mode = false, 

            action = function (t)
                if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                    t.action_map[t.select_index](t)
                end
            end, 

        }, 
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

        [8] = "Enable GPS", 
        [9] = "Enable LCD", 
        [10]= "Show static image(LCD)", 
        [11]= "Enable slide show", 
        [12]= "Enable LED test", 
        [13]= "Active Clone cable", 
    }

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
