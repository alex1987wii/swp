#!/usr/bin/lua

require "utility"
require "posix"

get_abb_reg = function (reg)
	return function()
		os.execute("echo "..reg.." >  /sys/devices/virtual/validate_ad6855/validate_ad6855/address")
		return read_attr_file("/sys/devices/virtual/validate_ad6855/validate_ad6855/data")
	end
end

bat_attr = function(name)
	return tostring(read_attr_file("/sys/devices/platform/battery/"..name))
end

log_bat_status = function ()
	local mt = {
		update = function(self)
				local bat_tcnt = bat_tcnt or time_counter()
				self[1] = "time cnt(s) : "..tostring(bat_tcnt()) 
				self[2] = "curr : vchg : event->".." "..bat_attr("charge_current") .." : "..bat_attr("vchg").." : "..bat_attr("charger_event")
				self[3] = "status : "..bat_attr("status")
				self[4] = "abb reg 0x36 : "..tostring(get_abb_reg("0x36")())
				self[5] = "abb reg 0x11 : "..tostring(get_abb_reg("0x11")())
				self[6] = "abb reg 0x37 : "..tostring(get_abb_reg("0x37")())
				self[7] = "abb reg 0x38 : "..tostring(get_abb_reg("0x38")())
				self[8] = "abb reg 0x3A : "..tostring(get_abb_reg("0x3A")())
				self[9] = "abb reg 0x3B : "..tostring(get_abb_reg("0x3B")())
				self[10] = "abb reg 0x3C : "..tostring(get_abb_reg("0x3C")())
				self[11] = "abb reg 0x3D : "..tostring(get_abb_reg("0x3D")())
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
		posix.sleep(60)
	end
end
