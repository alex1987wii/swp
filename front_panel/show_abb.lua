#!/usr/bin/lua

require "utility"

get_abb_reg = function (reg)
    return function()
        os.execute("echo "..reg.." >  /sys/devices/virtual/validate_ad6855/validate_ad6855/address")
        return read_attr_file("/sys/devices/virtual/validate_ad6855/validate_ad6855/data")
    end
end


local abb_chg_show = function()
    local ss = {}
    ss[1] = "abb reg 0x36 : "..tostring(get_abb_reg("0x36")())
    ss[2] = "abb reg 0x11 : "..tostring(get_abb_reg("0x11")())
    ss[3] = "abb reg 0x37 : "..tostring(get_abb_reg("0x37")())
    ss[4] = "abb reg 0x38 : "..tostring(get_abb_reg("0x38")())
    ss[5] = "abb reg 0x3A : "..tostring(get_abb_reg("0x3A")())
    ss[6] = "abb reg 0x3B : "..tostring(get_abb_reg("0x3B")())
    ss[7] = "abb reg 0x3C : "..tostring(get_abb_reg("0x3C")())
    ss[8] = "abb reg 0x3D : "..tostring(get_abb_reg("0x3D")())

    for i in ipairs(ss) do
        print(i, ss[i])
    end

end

abb_chg_show()
