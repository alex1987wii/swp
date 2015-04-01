
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

defunc_rx_desense_spkr = {
    start = function (list_index)
        return function (t)
            local r, msgid
            if t.select_status[list_index] then
            
                local setting = require("rx_desense_setting")
                if nil == setting then
                    slog:win("can not get the setting from file: /usr/local/share/lua/5.1/rx_desense_setting.lua")
                    return
                end
                
                r, msgid = ldsp.rx_desense_spkr_enable(setting.pcm_file_path)
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

