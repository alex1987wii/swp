-- ldsp.lua 
require "log"

local info = lua_log.i or print

ldsp = {
    bit_launch_dsp = function()  
        info("ldsp", "bit_launch_dsp")
    end, 
    register_callbacks = function() 
        info("ldsp", "register_callbacks")
    end, 
    start_dsp_service = function() 
        info("ldsp", "start_dsp_service")
    end, 
    start_rx_desense_scan = function(...)
        local argstr = ""
        for k=1, arg.n do
            argstr = argstr..arg[k]..", "
        end
        info("ldsp", "start_rx_desense_scan", "type "..type(argstr).." "..(tostring(argstr) or " nil"))
    end, 
    stop_rx_desense_scan =function(...)
        local argstr = ""
        for k=1, arg.n do
            argstr = argstr..arg[k]..", "
        end
        info("ldsp", "stop_rx_desense_scan", "type "..type(argstr).." "..(tostring(argstr) or " nil"))
    end, 
    two_way_transmit_start = function(...)
        local argstr = ""
        for k=1, arg.n do
            argstr = argstr..arg[k]..", "
        end
        info("ldsp", "two_way_transmit_start", "type "..type(argstr).." "..(tostring(argstr) or " nil"))
    end, 
    two_way_transmit_stop =function(...)
        local argstr = ""
        for k=1, arg.n do
            argstr = argstr..arg[k]..", "
        end
        info("ldsp", "two_way_transmit_stop", "type "..type(argstr).." "..(tostring(argstr) or " nil"))
    end, 
    tx_duty_cycle_test_start = function(...)
        local argstr = ""
        for k=1, arg.n do
            argstr = argstr..arg[k]..", "
        end
        info("ldsp", "tx_duty_cycle_test_start", "type "..type(argstr).." "..(tostring(argstr) or " nil"))
    end, 
    tx_duty_cycle_test_stop =function(...)
        local argstr = ""
        for k=1, arg.n do
            argstr = argstr..arg[k]..", "
        end
        info("ldsp", "tx_duty_cycle_test_stop", "type "..type(argstr).." "..(tostring(argstr) or " nil"))
    end, 
}

