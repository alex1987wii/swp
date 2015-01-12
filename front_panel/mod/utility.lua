
--utility.lua 

read_attr_file = function(f)
    local f = assert(io.open(f, "r"))
    local s = f:read("*all")
    f:close()
    return s
end

read_bootmode = function()
    return read_attr_file("/sys/sysdevs/bootmode")
end

read_config_mk_file = function (fname, key)
    for line in io.lines(fname) do
        local a, b = string.find(line, key)
        local val
        if a and b then
            val = string.sub(line, b+2, -1)
            return val
        end
    end

    return nil
end

switch_self_refresh = function(flag)
    if "boolean" ~= type(flag) then
        posix.syslog(posix.LOG_ERR, "switch_self_refresh: flag type error")
        return false
    end
    if flag then
        os.execute("echo 1 > /sys/devices/platform/ad6900-lcd/self_refresh")
    else
        os.execute("echo 0 > /sys/devices/platform/ad6900-lcd/self_refresh")
    end
    
    return true
end

function time_counter()
	local t_start = os.date("*t", os.time())
	local s_tmp = t_start.hour * 60 * 60 +t_start.min*60 + t_start.sec 
	return function ()
		local t_end = os.date("*t", os.time())
		local e_tmp = t_end.hour * 60 * 60 +t_end.min*60 + t_end.sec
		return (e_tmp - s_tmp)
	end
end


function check_num_range(num, ...)
    if "number" ~= type(num) then
        return false
    end
    local upper, low
    if arg.n == 2 then
        upper = arg[1]
        low = arg[2]
        if upper < low then
            upper, low = low, upper
        end
        
        if (num > upper) or (num < low) then
            return false
        end
    end
    
    return true
end

function check_num_parameters(...)
    slog:notice("check_num_parameters arg.n: "..tostring(arg.n))
    for i=1, arg.n do
        slog:notice("check_num_parameters arg["..i.."]: "..tostring(arg[i]))
        if nil == arg[i] then
            return {ret = false, errno = i, errmsg="arg["..i.."] nil"}
        end
        
        if "number" ~= type(arg[i]) then
            return {ret = false, errno = i, errmsg="arg["..i.."] wrong type, not number"}
        end
    end
    
    return {ret = true}
end

thread_do = function (func)
    local pid = posix.fork()
    
    if pid == 0 then
        if "function" == type(func) then
            func()
        end
        
        posix._exit(0)
    end
    
    return pid
end
