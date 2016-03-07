#!/usr/bin/lua

require "utility"
require "posix"

bat_status = {
    update = function(self)
        self.status = read_attr_file("/sys/devices/platform/battery/status")
        self.status_tab = get_item_from_formats(self.status)
        self.vbat = tonumber(self.status_tab[5])
        self.capacity = tonumber(self.status_tab[7])
        self.errcode = tonumber(self.status_tab[8])
        self.event = read_attr_file("/sys/devices/platform/battery/charger_event")

        local bat_tcnt = bat_tcnt or time_counter()
        self[1] = "time cnt(s) : "..tostring(bat_tcnt())
        self[2] = self.status
        self[3] = "event: "..tostring(self.event)
    end,
    show = function(self)
        for k, v in ipairs(self) do
            posix.syslog(posix.LOG_NOTICE, v)
        end
    end
}

bat_tcnt = time_counter()

while true do
    bat_status:update()
    if bat_status.capacity < 5 then
        os.execute("echo 0xff > /sys/unidebug/battery")
    end
--[[
    if bat_status.event == 255 then
        os.execute("echo 0xff > /sys/unidebug/battery")
    end
--]]
    bat_status:show()
    os.execute("dmesg -c >> /userdata/dmesg.log")
    posix.sleep(30)
end
