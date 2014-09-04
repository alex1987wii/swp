-- dsp / nondsp test process
require "log"
require "ldsp"
require "lnondsp"
require "posix"

local lua_log = lua_log or newlog("test_func")

process_do = function(func, t)
	local pid = posix.fork()
    
	if pid == 0 then
        if "function" == type(func) then
            func(t)
        end
        
        posix._exit(0)
    end
    
    return pid
end

test_init = function()
    local r, e = ldsp.bit_launch_dsp()
    if not r then
        posix.syslog(posix.LOG_ERR, "bit_launch_dsp fail: "..e)
        return false
    end
    
    ldsp.register_callbacks()
    local ret = ldsp.start_dsp_service()
    if not ret then
        posix.syslog(posix.LOG_ERR, "create thread dsp service fail")
        return false
    end
    
    lnondsp.register_callbacks()
    
    return true
end

BT_Test = function(t)
    
end
