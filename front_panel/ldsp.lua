-- ldsp.lua 

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
}
