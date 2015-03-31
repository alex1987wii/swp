
-- gsm_mode.lua 
require "log"
require "gsm"

GSM_MODE = {
    title = "GSM Active Test Mode", 
    tips  = "Press * to start Initial and Register", 
    multi_select_mode = true, 
    init_env = function (t)
        init_global_env()
    end, 
    action_map = {
        [1] = function (t) 
            t.gsm_band = t[1].gsm_band
        end, 
    }, 
    action = function (t)
        if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
            t.action_map[t.select_index](t)
        end
    end, 
    [1] = {
        title = "Set GSM Band", 
        tips  = "Select SM Band", 
        multi_select_mode = false, 
        action = function (t)
            local gsm_band_g = {0, 1, 2}  
            t.gsm_band = gsm_band_g[t.select_index]
        end, 
        "GSM 850/1900", 
        "GSM 900/1800",
        "GSM 850/900/1800/1900",
    }, 

    test_process = {
        [1] = function (t) end, 
    }, 
    stop_process = {
        [1] = function (t) end, 
    }, 
    test_process_start = function (t)
        
    end, 
    test_process_stop = function (t)

    end, 

}
 