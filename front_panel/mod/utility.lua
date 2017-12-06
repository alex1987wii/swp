
--utility.lua
require "log"
require "posix"
require "ldsp"
require "lnondsp"

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

read_attr_file = function(f)
    local f = io.open(f, "r")
    if nil == f then
        return nil
    end
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
    local t_start = os.time()
    return function ()
        local t_end = os.time()
        return os.difftime(t_end, t_start)
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

function get_para_func(pname, pinfo)
    return function (t)
        local r = get_number_in_window(t[t.select_index])
        if r.ret then
            t[pname] =  tonumber(r.str)
            if nil == t[pname] then
                slog:err("get string in window is not number: "..tostring(r.str))
                t.select_status[t.select_index] = false
                return false
            end

            if not check_num_range(t[pname]) then
                slog:err("enter is not number")
                return false
            end

            if string.len(pinfo) > (curses.cols() - 9) then
                t[t.select_index] = pinfo
            else
                t[t.select_index] = pinfo.." "..tostring(r.str)
            end
        else
            slog:err("enter "..r.errmsg)
        end
    end
end

local device_type = device_type or read_config_mk_file("/etc/sconfig.mk", "Project")

function init_global_env()
    if not global_env_init then
        ldsp.bit_launch_dsp()
        ldsp.register_callbacks()
        ldsp.start_dsp_service()

        lnondsp.register_callbacks()
        lnondsp.start_powerkey_service()
        --[[
        if "g4_bba" ~= device_type then
            lnondsp.bit_gps_thread_create()
        end
        --]]
        global_env_init = true
    end
end

try_read_fpl_test_mode_setting = function(f)
    local f = io.open(f, "r")
    if nil == f then
        return "00000000"
    end
    local s = f:read("*all")
    f:close()
    if 6 > string.len(s) then
        slog:err("fpl mode setting error")
        return "00000000"
    end

    return s
end

warning_tone = function (tm)
    local tcnt = time_counter()

    while tcnt() < tm do
        ldsp.baseband_spkr_start()
        posix.sleep(1)
        ldsp.baseband_spkr_stop()
        posix.sleep(1)
    end
end

function get_item_from_formats (str)
    local index = 0
    local stab = {cnt = 0}
    
    while true do
        local s_start, s_end, item_str =  string.find(str, "(%S+)", index)
        if nil == s_start then
            return stab
        else
            stab.cnt = stab.cnt + 1
            stab[stab.cnt] = item_str
            index = s_end + 1
        end
    end
end
