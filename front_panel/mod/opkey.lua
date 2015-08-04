-- opkey.lua 

require "log"
--require "lmm"
require "lfs"
require "lkey"

openkey = function(dev, flag)
	local fd
    if flag == "nonblock" then
        fd, errno= lfs.open(dev, "read", "nonblock")
    	if nil == fd or nil == fd.fd then
    		slog:err("opkey(), nonblock open "..dev)
    		return nil
        end
	else
        fd, errno= lfs.open(dev, "read")
        if nil == fd or nil == fd.fd then
            slog:err("opkey(), block read open "..dev)
            return nil
        end
    end

    return {
        readevts = function(s)
            local events = {}
            local evts = lkey.read_events(fd.fd, s)
            if evts.ret then
                for i, v in ipairs(evts) do 
                    events[i] = lkey.conv2table(evts[i])
                    if nil == events[i] then
                        slog:err("readevts, conv2table event["..i.."] error")
                        events.ret = false
                        return events
                    end

                end

                events.ret = true
                return events
            else
                events.ret = false
                events.errno=evts.errno
                events.errmsg=evts.errmsg
                return events
            end
        end, 
        
        read = function(buf, sz)
            return lfs.read(fd.fd, buf, sz)
        end, 
        
        select = function(t)
            return lfs.select(fd.fd, t)
        end, 
        
        close = function()
            lfs.close(fd.fd)
        end,
        
        read_pwr_status = function()
            local f = assert(io.open("/sys/devices/virtual/input/input0/pwr_status", "r"))
            local s = f:read("*all")
            f:close()
            return s
        end, 
        
        read_channel = function()
            local f = assert(io.open("/sys/devices/virtual/input/input0/cur_channel", "r"))
            local s = f:read("*all")
            f:close()
            return s
        end, 
        
        key_backlight = function(onoff)
            local f = assert(io.open("/sys/devices/virtual/input/input0/key_backlight", "w"))
            local s = f:write(onoff)
            f:close()
            return s
        end, 
    }
end
