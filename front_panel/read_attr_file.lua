
--read_attr_file.lua 

read_attr_file = function(f)
    local f = assert(io.open(f, "r"))
    local s = f:read("*all")
    f:close()
    return s
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
