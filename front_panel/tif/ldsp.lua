-- ldsp.lua 
require "log"

local info = lua_log.i or print

ldsp = {
    start_rx_desense_scan = function(...)
        local argstr = ""
        for k=1, arg.n do
            argstr = argstr..arg[k]..", "
        end
        info("start_rx_desense_scan", "type "..type(argstr).." "..(tostring(argstr) or " nil"))
    end, 
    stop_rx_desense_scan =function(...)
        local argstr = ""
        for k=1, arg.n do
            argstr = argstr..arg[k]..", "
        end
        info("stop_rx_desense_scan", "type "..type(argstr).." "..(tostring(argstr) or " nil"))
    end, 
    two_way_transmit_start = function(...)
        local argstr = ""
        for k=1, arg.n do
            argstr = argstr..arg[k]..", "
        end
        info("two_way_transmit_start", "type "..type(argstr).." "..(tostring(argstr) or " nil"))
    end, 
    two_way_transmit_stop =function(...)
        local argstr = ""
        for k=1, arg.n do
            argstr = argstr..arg[k]..", "
        end
        info("two_way_transmit_stop", "type "..type(argstr).." "..(tostring(argstr) or " nil"))
    end, 
    tx_duty_cycle_test_start = function(...)
        local argstr = ""
        for k=1, arg.n do
            argstr = argstr..arg[k]..", "
        end
        info("tx_duty_cycle_test_start", "type "..type(argstr).." "..(tostring(argstr) or " nil"))
    end, 
    tx_duty_cycle_test_stop =function(...)
        local argstr = ""
        for k=1, arg.n do
            argstr = argstr..arg[k]..", "
        end
        info("tx_duty_cycle_test_stop", "type "..type(argstr).." "..(tostring(argstr) or " nil"))
    end, 
}

ldsp.bit_launch_dsp()
ldsp.register_callbacks()
ldsp.start_dsp_service()

ldsp.start_rx_desense_scan(148012500,1,6250,6,6,10,2)
ldsp.stop_rx_desense_scan()
ldsp.tx_duty_cycle_test_start(148012500, 1, 0, 1, 1, 50, 10)
ldsp.tx_duty_cycle_test_start(148012500, 1, 0, 1, 2, 50, 10)
ldsp.tx_duty_cycle_test_start(148012500, 1, 0, 1, 3, 50, 10)
ldsp.tx_duty_cycle_test_start(148012500, 1, 0, 1, 4, 50, 10)
ldsp.tx_duty_cycle_test_start(148012500, 1, 0, 1, 5, 50, 10)
ldsp.tx_duty_cycle_test_start(148012500, 1, 0, 1, 8, 50, 10)

ldsp.tx_duty_cycle_test_stop()

ldsp.two_way_transmit_start(148012500,1,1,2,6250,10,2,2)
ldsp.two_way_transmit_stop()
