#!/usr/bin/lua

require "utility"
require "posix"

get_bat_attr = function(name)
    return tostring(read_attr_file("/sys/devices/platform/battery/"..name))
end

set_bat_attr = function(name, val)
    os.execute("echo "..val.." > /sys/devices/platform/battery/"..name)
end


bat_change_service = function (interval)
    local mt = {
        enable_chg = function(self)
            os.execute("echo 0x80 > //sys/devices/platform/battery/chgdac")
            os.execute("echo 1 > /sys/devices/platform/battery/chg_enable")
        end,
        disable_chg = function(self)
            os.execute("echo 0 > /sys/devices/platform/battery/chg_enable")
        end,
    }

    bat_tcnt = time_counter()

    while true do
        mt:enable_chg()
        posix.sleep(interval)

        mt:disable_chg()
        posix.sleep(interval)
    end
end

bat_change_service(10)
