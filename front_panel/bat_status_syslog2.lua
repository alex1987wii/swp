#!/usr/bin/lua

require "utility"
require "posix"

bat_attr = function(name)
        return tostring(read_attr_file("/sys/devices/platform/battery/"..name))
end

log_bat_status = function (t)
        local mt = {
                update = function(self)
                        self[1] = "status : "..bat_attr("status")
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
                posix.sleep(t)
        end
end

--log_bat_status(5)
