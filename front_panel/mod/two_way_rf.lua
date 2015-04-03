
-- two_way_rf.lua 

require "log"
require "ldsp"
require "baseband"

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
            else
                r, msgid = lnondsp.bt_txdata1_transmitter_stop()
            end
        end
    end, 
    
    stop = function (list_index)
        return function (t)
            if t.select_status[list_index] then
                lnondsp.bt_txdata1_transmitter_stop()
            end
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
                r_des, msgid_des = ldsp.fcc_start(tab.freq, tab.band_width, tab.power, tab.audio_path, tab.squelch, tab.modulation)
            end
        end
    end, 
    
    stop = function (list_index)
        return function (t)
            if t.select_status[list_index] then
                ldsp.fcc_stop()
            end
        end
    end
}

wait_for_rx_desense_scan_stop = function (t, list_index)
    if t.select_status[list_index] then
        repeat
            posix.sleep(1)
        until ldsp.rx_desense_scan_flag_get()
    end
end

wait_for_two_way_transmit_stop = function (t, list_index)
    if t.select_status[list_index] then
        repeat
            posix.sleep(1)
        until ldsp.two_way_transmit_flag_get()
    end
end

defunc_rx_desense_scan = {
    start = function (list_index)
        return function (t)
            if t.select_status[list_index] then
                local cr = check_num_parameters(t.freq, t.band_width, t.step_size, t.step_num, t.msr_step_num, t.samples, t.delaytime, t.pfm_path)
                if cr.ret then
                    ldsp.start_rx_desense_scan(t.freq, t.band_width, t.step_size, t.step_num, t.msr_step_num, t.samples, t.delaytime, t.pfm_path)
                else
                    slog:win("parameter error: check the setting file "..cr.errno.." "..cr.errmsg)
                end
            end
        end
    end, 
    
    stop = function (list_index)
        return function (t)
            if t.select_status[list_index] then
                ldsp.stop_rx_desense_scan()
            end
        end
    end
}


defunc_rx_desense_spkr = {
    start = function (list_index)
        return function (t)
            if t.select_status[list_index] then
            
                local func = loadfile("/usr/local/share/lua/5.1/rx_desense_setting.lua")
                if nil == func then
                    slog:win("can not get the file: /usr/local/share/lua/5.1/rx_desense_setting.lua")
                    return
                end
                local setting = func()
                if "table" ~= type(setting) then
                    slog:win("can not get setting from the file: /usr/local/share/lua/5.1/rx_desense_setting.lua")
                    return
                end
                
                if nil == setting.pcm_file_path then
                    slog:win("can not get pcm file path in: /usr/local/share/lua/5.1/rx_desense_setting.lua")
                    return
                end
                
                local ff = io.open(setting.pcm_file_path)
                if  nil == ff then
                    slog:win("the pcm file non-existent :"..tostring(setting.pcm_file_path))
                    return
                end
                ff:close()
                
                ldsp.rx_desense_spkr_enable(setting.pcm_file_path)
            end
        end
    end, 
    
    stop = function (list_index)
        return function (t)
            if t.select_status[list_index] then
                ldsp.rx_desense_spkr_stop()
            end
        end
    end
}

defunc_rx_desense_spkr_action = function (list_index)
    return function (t)
        local func = loadfile("/usr/local/share/lua/5.1/rx_desense_setting.lua")
        if nil == func then
            slog:win("can not get the file: /usr/local/share/lua/5.1/rx_desense_setting.lua")
            return
        end
        local setting = func()
        if "table" ~= type(setting) then
            slog:win("can not get setting from the file: /usr/local/share/lua/5.1/rx_desense_setting.lua")
            return
        end
        
        if nil == setting.pcm_file_path then
            slog:win("can not get pcm file path in: /usr/local/share/lua/5.1/rx_desense_setting.lua")
            return
        end
        
        local ff = io.open(setting.pcm_file_path)
        if  nil == ff then
            slog:win("the pcm file non-existent :"..tostring(setting.pcm_file_path))
            t.select_status[list_index] = false
            return
        end
        ff:close()
        
    end
end
