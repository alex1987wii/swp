
require "lnondsp"
require "nondsp_event_info"
require "log"
require "utility"

gps =  {
	cold_start = lnondsp.GPS_COLD_START, 
	warm_start = lnondsp.GPS_WARM_START,
	hot_start  = lnondsp.GPS_HOT_START,
	enable_call = false, 
	
    get_req_state = function (t, wait_time)
    	if "number" ~= type(wait_time) then
			slog:err("gps get_req_state arg 2, wait time is not number(unit:s)")
			return {ret=false, errmsg="gps get_req_state arg 2, wait time is not number(unit:s)"} 
		end
		
		local time_cnt = time_counter()
		while time_cnt() < tonumber(wait_time) do
			local evt_index = lnondsp.get_evt_number()
			local evt
			if 0 == evt_index then
				slog:notice("event cnt: 0, wait 1s and retry")
				posix.sleep(1)
			else
				evt = lnondsp.get_evt_item(1)
				if not evt.ret then
					slog:err("get evt item("..tostring(evt_index)..") err: "..evt.errno..":"..evt.errmsg)
					return {ret=false, errmsg="gps get_req_state, nonsupport event item"}
				end
				
				local e_id = NONDSP_EVT:get_id(evt.evt, evt.evi)
				if e_id == "GPS_REQ_RESULT" then
					slog:notice("GPS_REQ_RESULT state: "..tostring(evt.state))
                    if evt.state then
                        return (ret=true, state=evt.state)
                    else
                        return (ret=false, errmsg="req state -> "..tostring(evt.state))
                    end
				end
				slog:notice("gps get_req_state, get event: "..tostring(e_id))
			end
		end
		
		return {ret=false, errmsg="gps get_req_state time out("..tostring(wait_time).." s)"} 
    end, 
    
	enable = function (t)
		if not t.enable_call then
			lnondsp.enable()
            local r = t:get_req_state(5)
            if r.ret then
                t.enable_call = true
            else
                slog:err("gps:enable error -> "..r.errmsg)
                return false
            end
		end
        
        return true
	end, 
	
	restart = function (t, restart_mode)
		if nil ~= t[restart_mode] and "number" == type(t[restart_mode]) then
			lnondsp.gps_restart(t[restart_mode])
			slog:notice("gps restart: "..tostring(restart_mode)..": "..tostring(t[restart_mode]))
		else
			slog:err("gps restart mode error: "..tostring(restart_mode))
            return false
		end
        
        local r = t:get_req_state(5)
        if r.ret then
            t.enable_call = true
        else
            slog:err("gps:restart error -> "..r.errmsg)
            return false
        end
        
        return true
	end, 
	
	get_fixed = function (t, wait_time)
		if "number" ~= type(wait_time) then
			slog:err("gps get_fixed arg 2, wait time is not number(unit:s)")
			return {ret=false, errmsg="gps get_fixed arg 2, wait time is not number(unit:s)"} 
		end
		
        lnondsp.gps_get_position_fix()
        
		local time_cnt = time_counter()
		while time_cnt() < tonumber(wait_time) do
			local evt_index = lnondsp.get_evt_number()
			local evt
			if 0 == evt_index then
				slog:notice("event cnt: 0, wait 1s and retry")
				posix.sleep(1)
			else
				evt = lnondsp.get_evt_item(1)
				if not evt.ret then
					slog:err("get evt item("..tostring(evt_index)..") err: "..evt.errno..":"..evt.errmsg)
					return {ret=false, errmsg="gps get_fixed, nonsupport event item"}
				end
				
				local e_id = NONDSP_EVT:get_id(evt.evt, evt.evi)
				if e_id == "GPS_REQ_RESULT" then
					slog:notice("GPS_REQ_RESULT state: "..tostring(evt.state))
				elseif e_id == "GPS_FIXED" then
                    if evt.fixed then
                        for k, v in pairs(evt) do
                            slog:notice("gps status: "..k.." : "..tostring(v))
                        end
                    end
					return evt
				end
				slog:notice("gps get_fixed, get event: "..tostring(e_id))
			end
		end
		
		return {ret=false, errmsg="gps get_fixed time out("..tostring(wait_time).." s)"} 
	end, 
	
	hw_test_start = function(t, svid, period)
		lnondsp.gps_hardware_test(svid, period)
        
        local r = t:get_req_state(5)
        if r.ret then
            t.enable_call = true
            return true
        end
        
        slog:err("gps:gps_hardware_test req error -> "..r.errmsg)
        return false
	end, 
	
	hw_test_stop = function(t)
		lnondsp.gps_enable()
        
        local r = t:get_req_state(5)
        if r.ret then
            t.enable_call = true
        else
            slog:err("gps:hw_test_stop -> gps_enable req error -> "..r.errmsg)
            return false
        end
        
        return true
	end, 
		
	get_hw_info = function (t, wait_time)
		if "number" ~= type(wait_time) then
			slog:err("gps get_hw_info arg 2, wait time is not number(unit:s)")
			return {ret=false, errmsg="gps get_hw_info arg 2, wait time is not number(unit:s)"} 
		end
		
		local time_cnt = time_counter()
		while time_cnt() < tonumber(wait_time) do
			local evt_index = lnondsp.get_evt_number()
			local evt
			if 0 == evt_index then
				slog:notice("event cnt: 0, wait 1s and retry")
				posix.sleep(1)
			else
				evt = lnondsp.get_evt_item(evt_index)
				if not evt.ret then
					slog:err("get evt item("..tostring(evt_index)..") err: "..evt.errno..":"..evt.errmsg)
					return {ret=false, errmsg="gps get_hw_info, nonsupport event item"}
				end
				
				local e_id = NONDSP_EVT:get_id(evt.evt, evt.evi)
				if e_id == "GPS_REQ_RESULT" then
					slog:notice("GPS_REQ_RESULT state: "..tostring(evt.state))
				elseif  e_id == "TEST_MODE_INFO" then
					for k, v in pairs(evt) do
						slog:notice("gps hw info: "..k.." : "..tostring(v))
					end
					return evt
				end
				slog:notice("gps get_hw_info, get event: "..tostring(e_id))
			end
		end
		
		return {ret=false, errmsg="gps get_hw_info time out("..tostring(wait_time).." s)"} 
	end, 

	hw_test = function(t, svid, period, num)
		if not t:hw_test_start(svid, period) then
            slog:err("gps:hw_test start error")
            return false
        end
        
		for i=1, num do
			slog:notice("get hw info index "..i)
			local r = t:get_hw_info(30)
			if not r.ret then
				slog:err("get hw info error: "..tostring(r.errmsg))
			end
		end
		
		t:enable()
        return true
	end, 
	
	disable = function(t)
		lnondsp.gps_disable()
        
        local r = t:get_req_state(5)
        if r.ret then
            t.enable_call = false
        else
            slog:err("gps:disable req error -> "..r.errmsg)
        end
	end
}

update_list_defunc = function (tab, menu_list, val_list, index_num, used_time) 
    if "table" ~= type(menu_list) then
        slog:err("menu_tab.update_list list is not table")
        return false
    end
    
    tab[1] = "index num: "..index_num
    
    for k, v in ipairs(list) do
        local val
        if nil == val_list or nil == val_list[k] then
            val = "nil"
        else
            val = val_list[k]
        end
        tab[table.getn(tab)+1] = v..": "..tostring(val)
    end
    
    tab[table.getn(tab)+1] = "used time: "..tostring(used_time)
end
--
defunc_gps_functional_test = {
    start = function(list_index)
        return function (t)
            if ("string" ~= type(t.restart_mode)) or (not check_num_parameters(t.measurement_num).ret) then
                slog:err("gps_functional_test parameters error: "..tostring(t.restart_mode)..", "..tostring(t.measurement_num))
                return false
            end

            local show_list = {
                [1] = "fixed", 
                [2] = "TTFF",  
                [3] = "latitude",  
                [4] = "longitude",  
                [5] = "altitude",  
            }
            local menu_tab = {
                title = "GPS functional test", 
                tips  = "Testing... The test will stop automatically", 
                multi_select_mode = false, 
            }
            
            menu_tab.update_list = update_list_defunc
            
            menu_tab:update_list(show_list, nil, 0, 0)
            create_main_menu(menu_tab):show()
            
            local unity_time_cnt = time_counter()
            for index=1, t.measurement_num do
                slog:notice("index "..index)
                local time_cnt = time_counter()
                local info = {}
                repeat
                    if not gps:restart(t.restart_mode) then
                        slog:err("index "..index.." restart error: <- "..tostring(t.restart_mode))
                        menu_tab:update_list(show_list, nil, index, time_cnt())
                        menu_tab.title = "GPS functional test ("..unity_time_cnt()..")"
                        create_main_menu(menu_tab):show()
                        return false
                    end
                
                    info = gps:get_fixed(30)
                    if info.ret then
                        menu_tab:update_list(show_list, info, index, time_cnt())
                        menu_tab.title = "GPS functional test ("..unity_time_cnt()..")"
                        create_main_menu(menu_tab):show()
                    else
                        slog:err("gps:get_fixed error: "..info.errmsg)
                    end
                    posix.sleep(1)
                until info.fixed
                
            end

        end
    end, 
    
    stop = function(list_index)
        return function (t)
        
        end
    end
}

defunc_gps_hw_test = {
    start = function(list_index)
        return function (t)
            if not t.select_status[list_index] then
                return false
            end
            
            local c_r = check_num_parameters(t.svid, t.trancking_time, t.interval, t.measurement_num)
            if not c_r.ret then
                slog:win("Check parameters error")
                return false
            end
            
            local show_list = {
                [1] = "index num: ", 
                [2] = "SVid", 
                [3] = "bit_sync_time",  
                [4] = "CNo_mean",  
                [5] = "CNo_sigma",  
                [6] = "clock_drift", 
                [7] = "clock_offset", 
                [8] = "Abs_I20ms", 
                [9] = "Abs_Q20ms", 
                [10] = "rtc_freq", 
                [11] = "agc", 
                [12] = "noise_figure", 
                [13] = "Q_I_ratio",  
            }
            local menu_tab = {
                title = "GPS Hardware test", 
                tips  = "Testing... The test will stop automatically", 
                multi_select_mode = false, 
            }
            menu_tab.update_list = update_list_defunc
            
            menu_tab:update_list(show_list, nil, 0, 0)
            create_main_menu(menu_tab):show()
            
            local unity_time_cnt = time_counter()
            
            if not gps:hw_test_start(t.svid, t.trancking_time) then
                menu_tab.title = "GPS Hardware test ("..unity_time_cnt()..")"
                menu_tab:update_list(show_list, nil, index, time_cnt())
                create_main_menu(menu_tab):show()
                return false
            end

            for index=1, t.measurement_num do
                slog:notice("index "..index)
                local time_cnt = time_counter()
                local info = {}
                repeat
                    info = gps:get_hw_info (t.trancking_time + 30)
                    if info.ret then
                        menu_tab.title = "GPS Hardware test ("..unity_time_cnt()..")"
                        menu_tab:update_list(show_list, info, index, time_cnt())
                        create_main_menu(menu_tab):show()
                    else
                        slog:err("gps:get_hw_info error: "..info.errmsg)
                    end
                    posix.sleep(1)
                until info.fixed
                
                posix.sleep(t.interval)
            end

            gps:enable()
        end
    end, 
    
    stop = function(list_index)
        return function (t)
            gps:disable()
        end
        
    end
}
--
