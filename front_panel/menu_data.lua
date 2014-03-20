-- menu data 

--require "ldsp"
--require "lnondsp"

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
            [1] = {
                title = "Band Width", 
                tips  = "Select Band Width", 
                multi_select_mode = false, 
                action = function ()
                    
                end, 
                "12.5 KHz", 
                "25 KHz", 
            }, 
            [2] = "Num of measurements", 
            [3] = "Sample size", 
            [4] = "Time between measurements(ms)", 
            [5] = "Start frequency(Hz)", 
            [6] = "Number of stemps", 
            [7] = {
                title = "Step size", 
                tips  = "Select Step size", 
                multi_select_mode = false, 
                action = function ()

                end, 
                "0    Hz", 
                "2.5  KHz", 
                "6.25 KHz", 
                "12.5 KHz", 
                "25   KHz", 
                "100  KHz", 
                "1    MHz", 
            }, 
            [8] = {
                title = "Enable Bluetooth", 
                tips  = "Setting up bluetooth device", 
                multi_select_mode = false, 
                action = function ()
                    
                end, 
            }, 
            [9] = "Enable GPS", 
            [10] = "Enable LCD", 
            [11]= "Show static image(LCD)", 
            [12]= "Enable slide show", 
            [13]= "Enable LED test", 
            [14]= {
                title = "Enable RS232 test", 
                tips  = "Select Enable RS232 test", 
                multi_select_mode = false, 
                action = function ()

                end, 
                "1200", 
                "2400", 
                "4800", 
                "9600", 
                "19200", 
                "34800", 
                "57600",
                "115200" 
            }, 
        }, 
        
        [2] = {
            title = "Rx Antenna Test", 
            tips  = "* start; up down key move to config", 
            multi_select_mode = true, 
            new_main_menu = function (t)
                local m_sub = create_main_menu(t)
                m_sub:show()
                m_sub:action()
            end, 
            [1] = {
                title = "Band Width", 
                tips  = "Select Band Width", 
                multi_select_mode = false, 
                action = function ()

                end, 
                "12.5 KHz", 
                "25 KHz", 
            }, 
            [2] = "Num of measurements", 
            [3] = "Sample size", 
            [4] = "Time between measurements(ms)", 
            [5] = "Start frequency(Hz)", 
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
            [1] = {
                title = "Freq", 
                tips  = "Select Freq", 
                multi_select_mode = false, 
                action = function (t)
                    local instr = ""
                    if (t.select_index ~= nil) and (t.select_index == 4) then
                        local r = get_string_in_window(t[t.select_index])
                        if r.ret then
                            t.enter_freq = tonumber(r.str)
                            t[t.select_index] = "Enter "..t.enter_freq
                        else
                            lua_log.i("freq", "enter freq(Hz) "..r.errmsg)
                        end
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
                action = function ()

                end, 
                "12.5 KHz", 
                "25 KHz", 
            }, 
            [3] = {
                title = "Power", 
                tips  = "Select Power", 
                multi_select_mode = false, 
                action = function ()

                end, 
                "1 Watt", 
                "2 Watt", 
                "3 Watt",
            }, 
            [4] = {
                title = "Audio Path", 
                tips  = "Select Audio Path", 
                multi_select_mode = false, 
                action = function ()

                end, 
                "Internal mic", 
                "External mic", 
            }, 
            [5] = {
                title = "Modulation", 
                tips  = "Select Modulation", 
                multi_select_mode = false, 
                action = function ()

                end, 
                "none", 
                "CTCSS", 
                "CDCSS", 
                "2 tone", 
                "5/6 tone", 
                "Modem(Digital 4FSK)", 
                "MDC1200", 
                "DTMF", 
            }, 
            [6] = {
                title = "Tx ON/OFF Time Setting", 
                tips  = "Select and input the start/stop time", 
                multi_select_mode = true, 
                action = function ()

                end, 
                "Tx on time(s)", 
                "Tx off time(s)", 
            }, 
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
            [1] = {
                title = "Power", 
                tips  = "Select Power", 
                multi_select_mode = false, 
                action = function ()

                end, 
                "1 Watt", 
                "2 Watt", 
                "3 Watt",
            }, 
            [2] = {
                title = "Start delay(sec)", 
                tips  = "Enter start delay in seconds.Ranging frome 1 to 10000 s", 
                multi_select_mode = false, 
                action = function ()

                end, 
                "Enter ...", 
            }, 
            [3] = {
                title = "Transmission on time (sec)", 
                tips  = "Enter transmission on time in seconds.Ranging frome 1 to 10000 s", 
                multi_select_mode = false, 
                action = function ()

                end, 
                "Enter ...", 
            }, 
            [4] = {
                title = "Transmission off time (sec)", 
                tips  = "Enter transmission off time in seconds.Ranging frome 1 to 10000 s", 
                multi_select_mode = false, 
                action = function ()

                end, 
                "Enter ...", 
            }, 
            [5] = {
                title = "Frequency List", 
                tips  = "Select Frequency", 
                multi_select_mode = false, 
                action = function (t)
                    local instr = ""
                    if (t.select_index ~= nil) and (t.select_index == 4) then
                        local r = get_string_in_window(t[t.select_index])
                        if r.ret then
                            t.enter_freq = tonumber(r.str)
                            t[t.select_index] = "Enter "..t.enter_freq
                        else
                            lua_log.i("freq", "enter freq(Hz) "..r.errmsg)
                        end
                    end
                end, 
                [1] = "none (the end of menu)", 
                [2] = "start freq (Hz)",
                [3] = {
                    title = "Step size", 
                    tips  = "Select the step size", 
                    multi_select_mode = false, 
                    action = function ()

                    end, 
                    "0 Hz(only on freq tested)", 
                    "1 MHz", 
                    "2 MHz", 
                    "5 MHz", 
                }, 
                [4] = "Number of steps",  -- a non-zero number 
                
                -- wait for test status 
            }, 
        
        }

    }, 
    FCC = {
        title = "Front Panel", 
        tips  = "Select the test item, move and space to select", 
        multi_select_mode = true, 
        action = function (t)

        end, 

        [1] = {
            title = "Freq", 
            tips  = "Select Freq", 
            multi_select_mode = false, 
            action = function (t)
                local instr = ""
                if (t.select_index ~= nil) and (t.select_index == 4) then
                    local r = get_string_in_window(t[t.select_index])
                    if r.ret then
                        t.enter_freq = tonumber(r.str)
                        t[t.select_index] = "Enter "..t.enter_freq
                    else
                        lua_log.i("freq", "enter freq(Hz) "..r.errmsg)
                    end
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
            action = function ()

            end, 
            "12.5 KHz", 
            "25 KHz", 
        }, 
        [3] = {
            title = "Power", 
            tips  = "Select Power", 
            multi_select_mode = false, 
            action = function ()

            end, 
            "1 Watt", 
            "2 Watt", 
            "3 Watt",
        }, 
        [4] = {
            title = "Audio Path", 
            tips  = "Select Audio Path", 
            multi_select_mode = false, 
            action = function ()

            end, 
            "Internal speaker / mic", 
            "External speaker / mic", 
            "BlueTooth (attempt to auto  pair)", 
        }, 
        [5] = {
            title = "Squelch", 
            tips  = "Select Squelch", 
            multi_select_mode = false, 
            action = function ()

            end, 
            "none", 
            "normal", 
            "tight", 
        }, 
        [6] = {
            title = "Modulation", 
            tips  = "Select Modulation", 
            multi_select_mode = false, 
            action = function ()

            end, 
            [1] = "none", 
            [2] = {
                title = "Analog", 
                tips  = "Select Analog", 
                multi_select_mode = false, 
                action = function ()

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
