
-- two_way_rf.lua 

require "log"
require "ldsp"
require "baseband"
require "utility"

local device_type = device_type or read_config_mk_file("/etc/sconfig.mk", "Project")

defunc_2way_ch1_knob_action = function (list_index)
    return function (t)
        local func = loadfile("/usr/local/share/lua/5.1/2way_ch1_knob_setting.lua")
        if nil == func then
            slog:win("can not get the file: /usr/local/share/lua/5.1/2way_ch1_knob_setting.lua")
            t.select_status[list_index] = false
            return
        end
        local setting = func()
        if "table" ~= type(setting) then
            slog:win("can not get setting from the file: /usr/local/share/lua/5.1/2way_ch1_knob_setting.lua")
            t.select_status[list_index] = false
            return
        end
    end
end

defunc_2way_ch1_knob_settings = {
    start = function (list_index) 
        return function (t)
           
			local func = loadfile("/usr/local/share/lua/5.1/2way_ch1_knob_setting.lua")
			if nil == func then
				slog:win("can not get the file: /usr/local/share/lua/5.1/2way_ch1_knob_setting.lua")
				return
			end
			
			local setting = func()
			if "table" ~= type(setting) then
				slog:win("can not get setting from the file: /usr/local/share/lua/5.1/2way_ch1_knob_setting.lua")
				return
			end
            local tab = setting
            if tab.freq == 0 then
				if "u3" == tostring(device_type) then
					tab.freq = 136000000
				elseif "u3_2nd" == tostring(device_type) then
					tab.freq = 763000000
				else
					slog:win("Warming!!! 2way_ch1_knob_setting: not support device type "..tostring(device_type))
                    t.select_status[list_index] = false
					return nil
				end
			end
			
            if t.select_status[list_index] then
                ldsp.fcc_start(tab.freq, tab.band_width, tab.power, tab.audio_path, tab.squelch, tab.modulation)
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


defunc_rx_desense_action = function (list_index)
    return function (t)
        local func = loadfile("/usr/local/share/lua/5.1/rx_desense_setting.lua")
        if nil == func then
            slog:win("can not get the file: /usr/local/share/lua/5.1/rx_desense_setting.lua")
            t.select_status[list_index] = false
            return
        end
        local setting = func()
        if "table" ~= type(setting) then
            slog:win("can not get setting from the file: /usr/local/share/lua/5.1/rx_desense_setting.lua")
            t.select_status[list_index] = false
            return
        end

        t.freq = setting.freq
        t.band_width = setting.band_width
        t.step_size = setting.step_size
        t.step_num = setting.step_num
        t.msr_step_num = setting.msr_step_num
        t.samples = setting.samples
        t.delaytime = setting.delaytime
        t.pfm_path = setting.pfm_path
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
            t.select_status[list_index] = false
            return
        end
        local setting = func()
        if "table" ~= type(setting) then
            slog:win("can not get setting from the file: /usr/local/share/lua/5.1/rx_desense_setting.lua")
            t.select_status[list_index] = false
            return
        end
        
        if nil == setting.pcm_file_path then
            slog:win("can not get pcm file path in: /usr/local/share/lua/5.1/rx_desense_setting.lua")
            t.select_status[list_index] = false
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
