-- key_services.lua 

require "opkey"

key_action = {
--[[
    [1] = {
        keycode = 0x27, 
        keyvolue = 0, 
        active = function ()
            os.execute("/bin/rm -f /userdata/Settings/set_fpl_mode.lua")
            os.execute("/sbin/poweroff")
        end
    }, 
--]]
    [1] = {
        keycode = 0x27, 
        keyvolue = 0, 
        action = function ()
            os.execute("/bin/rm -f /userdata/Settings/set_fpl_mode.lua")
            os.execute("/sbin/poweroff")
        end
    }, 
    
}

wait_and_show_bat_status = function(t)
    local dev = "/dev/input/event0"
    local k = openkey(dev, "nonblock")
    if k == nil then
        slog:err("Err: open "..dev)
        return false
    end
    
    while true do
        local r_f, r_code = ldsp.fcc_battery_safe()
        -- slog:notice("fcc_battery_safe return code:"..tostring(r_code)) 
        if not r_f then
            switch_self_refresh(true)
            note_in_window_delay("battery not safe: "..tostring(r_code), 2)
            t.battery_err_show = true
        else
            if t.battery_err_show then
                switch_self_refresh(true)
                note_in_window_delay("battery safe", 2)
                t.battery_err_show = false
            end
        end
        
        local evts = k.readevts(lkey.event_size)
        if evts.ret then
			for k, v in ipairs(evts) do
                --note_in_window_delay("key code:value -> "..tostring(v.code)..":"..tostring(v.value), 2)
                
                --[[
                key code 33: *
                key code 34: #
                key value: 1 -> press, 0 -> release
                --]]
                if v.code == 34 and 0 == v.value then
                    t:test_process_stop()
                    t.test_process_start_call = false
                    switch_self_refresh(true)
                    return true
                end
            end 
        end
        
        --posix.sleep(1)
    end
end
