
--read_attr_file.lua 

read_attr_file = function(f)
    local f = assert(io.open(f, "r"))
    local s = f:read("*all")
    f:close()
    return s
end
