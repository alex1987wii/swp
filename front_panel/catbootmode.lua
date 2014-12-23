
--catbootmode.lua 

require "read_attr_file"

read_bootmode = function()
    return read_attr_file("/sys/sysdevs/bootmode")
end

--print(read_bootmode())


