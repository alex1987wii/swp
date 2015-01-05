
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
