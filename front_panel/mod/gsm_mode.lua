
-- gsm_mode.lua 
require "log"
require "gsm"
require "two_way_rf"

GSM_MODE = {
    title = "GSM Active Test Mode", 
    tips  = "Press * to start Initial and Register", 
    multi_select_mode = true, 
    init_env = function (t)
        init_global_env()
        gsm = gsm_init()
    end, 

    action_map = {
        [1] = function (t) 
            t.gsm_band = t[1].gsm_band
        end, 
        [2] = defunc_rx_desense_action(2), 
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
            local gsm = gsm or gsm_init()
            gsm.set_band(t.gsm_band)
        end, 
        "GSM 850/1900", 
        "GSM 900/1800",
        "GSM 850/900/1800/1900",
    }, 
    [2] = "Rx Desense Scan", 

    test_process = {
        [1] = defunc_gsm_init_register_test(1), 
        [2] = defunc_rx_desense_scan.start(2), 
    }, 
    stop_process = {
        [1] = function (t) 
            local gsm = gsm or gsm_init()
            gsm.disable()
        end, 
        [2] = defunc_rx_desense_scan.stop(2), 
    }, 
    test_process_start = function (t)
        switch_self_refresh(true)
        for i=1, table.getn(t) do
            if "function" == type(t.test_process[i]) then
                t.test_process[i](t)
            end
        end
        t.test_process_start_call = false
    end, 
    test_process_stop = function (t) 
        for i=1, table.getn(t) do
            if "function" == type(t.stop_process[i]) then
                t.stop_process[i](t)
            end
        end
    end

}
 
