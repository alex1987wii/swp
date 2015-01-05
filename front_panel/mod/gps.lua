
require "lnondsp"
require "nondsp_event_info"
require "log"
require "utility"

gps =  {
	cold_start = lnondsp.GPS_COLD_START, 
	warm_start = lnondsp.GPS_WARM_START,
	hot_start  = lnondsp.GPS_HOT_START,
	enable_call = false, 
	
	enable = function (t)
		if not t.enable_call then
			lnondsp.enable()
			t.enable_call = true
		end
	end, 
	
	restart = function (t, restart_mode)
		if nil ~= t[restart_mode] and "number" == type(t[restart_mode]) then
			lnondsp.gps_restart(t[restart_mode])
			slog:notice("gps restart: "..tostring(restart_mode)..": "..tostring(t[restart_mode]))
		else
			slog:err("gps restart mode error: "..tostring(restart_mode))
		end
	end, 
	
	get_fixed = function (t, wait_time)
		if "number" ~= type(wait_time) then
			slog:err("gps get_fixed arg 2, wait time is not number(unit:s)")
			return {ret=false, errmsg="gps get_fixed arg 2, wait time is not number(unit:s)"} 
		end
		
		local time_cnt = time_counter()
		while time_cnt() < tonumber(wait_time) do
			lnondsp.gps_get_position_fix()
			local evt_index = lnondsp.get_evt_number()
			local evt
			if 0 == evt_index then
				slog:notice("event cnt: 0, wait 1s and retry")
				posix.sleep(1)
			else
				evt = lnondsp.get_evt_item(evt_index)
				if not evt.ret then
					slog:err("get evt item("..tostring(evt_index)..") err: "..evt.errno..":"..evt.errmsg)
					return {ret=false, errmsg="gps get_fixed, nonsupport event item"}
				end
				
				local e_id = NONDSP_EVT:get_id(evt.evt, evt.evi)
				if e_id == "GPS_REQ_RESULT" then
					slog:notice("GPS_REQ_RESULT state: "..tostring(evt.state))
				elseif e_id == "GPS_FIXED" then
					for k, v in pairs(evt) do
						slog:notice("gps status: "..k.." : "..tostring(v))
					end
					return evt
				end
				slog:notice("gps get_fixed, get event: "..tostring(e_id))
			end
		end
		
		return {ret=false, errmsg="gps get_fixed time out("..tostring(wait_time).." s)"} 
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
	
	hw_test_start = function(t, svid, period)
		lnondsp.gps_hardware_test(svid, period)
	end, 
	
	hw_test_stop = function(t, svid, period)
		lnondsp.gps_enable()
	end, 
	
	hw_test = function(t, svid, period, num)
		lnondsp.gps_hardware_test(svid, period)
		for i=1, num do
			slog:notice("get hw info index "..i)
			local r = t:get_hw_info(30)
			if not r.ret then
				slog:err("get hw info error: "..tostring(r.errmsg))
			end
		end
		
		t:disable()
		t:enable()
	end, 
	
	disable = function(t)
		lnondsp.gps_disable()
		t.enable_call = false
	end
}

--
defunc_gps_functional_test = function(list_index)
    return function(t)

    end
end

defunc_gps_hw_test = function(list_index)
    return function(t)

    end
end
--
