--load_front_panel.lua 
#!/bin/lua

read_bootmode = function()
    local f = assert(io.open("/sys/sysdevs/bootmode", "r"))
    local s = f:read("*all")
    f:close()
    return s
end


