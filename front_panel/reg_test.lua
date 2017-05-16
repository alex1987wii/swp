#!/usr/bin/lua

require "utility"
require "posix"

get_reg = function (reg)
    return function()
        os.execute("echo "..reg.." >   /sys/devices/virtual/ebus_tool/ebus_control/address")
        return read_attr_file("/sys/devices/virtual/validate_ad6855/validate_ad6855/data")
    end
end

set_reg = function (reg)
    return function(data)
        os.execute("echo "..reg.." >   /sys/devices/virtual/ebus_tool/ebus_control/address")
        os.execute("echo "..data.." >   /sys/devices/virtual/ebus_tool/ebus_control/address")
    end
end



log_bat_status = function (interval)
    local mt = {
        update = function(self)
            local bat_tcnt = bat_tcnt or time_counter()
            os.execute("echo temp2 > /sys/class/adc/channel")
            local temp2 = read_attr_file("/sys/class/adc/channel")
            local bat_status = bat_attr("status")
            self[1] = "status("..tostring(bat_tcnt()).."s) : "..bat_attr("status").." : "..bat_attr("charge_current").." "..bat_attr("vchg").." "..temp2

            local status_tab = get_item_from_formats(bat_status)
            local chg_status = status_tab[2]
            local chg_curr = -tonumber(bat_attr("charge_current"))
            if (chg_status == "CHARGE_ERR") and (chg_curr > 100) then
                self[1] = self[1].." : "..tostring(get_abb_reg("0x36")())
            end
        end,
        show = function(self)
            for k, v in ipairs(self) do
                posix.syslog(posix.LOG_NOTICE, v)
            end
        end
    }

    bat_tcnt = time_counter()

    while true do
        mt:update()
        mt:show()
        posix.sleep(interval)
    end
end

-- log_bat_status(5)
