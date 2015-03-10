
-- field.lua 

require "log"
require "ldsp"
require "bluetooth"
require "gps"

defunc_calibrate_radio_oscillator_test = function(list_index)
    
    local menu_tab = {
        title = "Cal radiooscillator", 
        tips  = "Enter the afc value to setting, * to save it", 
        multi_select_mode = false, 
    }

    menu_tab.init_env = function (tab) 
        local r = ldsp.get_original_afc_val()
        if r.ret then
            tab.afc_val = r.afc_val
            slog:err("get_original_afc_val, afc_val "..tostring(tab.afc_val))
        end
        slog:notice("get_original_afc_val, afc_val "..tostring(tab.afc_val))
        tab[1] = "AFC Value: "..tostring(tab.afc_val)
        
        ldsp.calibrate_radio_oscillator_start()
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
        switch_self_refresh(true)
        ldsp.save_radio_oscillator_calibration()
        tab.test_process_start_call = false
    end
    
    menu_tab.test_process_stop = function (tab) end

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

Field_MODE = {
    title = "Field test", 
    tips  = "Press 1-5 to test\n  * unavailable now!", 
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
        [3] = function (t) 
            ldsp.calibrate_radio_oscillator_stop()
            slog:win("calibrate radio oscillator stop")
        end, 
        [4] = defunc_enable_bt(3), 
        [5] = function (t)
            if t.select_status[t.select_index] then
                if not t.select_status[t.select_index] then
                    t.test_process[5](t)
                    t.gps_enable_call = true
                end
            end
        end, 
    }, 
    action = function (t)
        if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
            t.action_map[t.select_index](t)
        end
        
        if t.gps_enable_call then
            if not t.select_status[5] then
                t.stop_process[5](t)
                t.gps_enable_call = false
            end
        end
    end, 
    [1] = "Start Oscillator Cal", 
    [2] = "Restore Oscillator Cal", 
    [3] = "Stop Oscillator Cal", 
    [4] = "Find BT Device", 
    [5] = "Enable GPS",  
        --[[ display to user'acquiring GPS signal'.Once acquired display to the user
              the 'latitude and longitude' of the fixes
        --]] 
    
    test_process = {
        [1] = function (t) end, 
        [2] = function (t) end, 
        [3] = function (t) end,  
        [4] = function (t) end,  
        [5] = defunc_enable_gps.start(5), 
    }, 
    stop_process = {
        [1] = function (t) end, 
        [2] = function (t) end, 
        [3] = function (t) end, 
        [4] = function (t) end, 
        [5] = defunc_enable_gps.stop(5), 

    }
}
