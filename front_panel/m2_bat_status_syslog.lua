#!/usr/bin/lua

require "utility"
require "posix"

local bat_cmd = {
    {cmd="0x00", name="MANUFACTURER_ACCESS"     , datatype="TYPE_HEX",  size=2, unit="-"}, 
    {cmd="0x01", name="REMAINING_CAPACITY_ALARM", datatype="TYPE_UINT", size=2, unit="mAh/10mWh"}, 
    {cmd="0x02", name="REMAINING_tIME_ALARM"    , datatype="TYPE_UINT", size=2, unit="min"}, 
    {cmd="0x03", name="BATTERY_MODE"            , datatype="TYPE_HEX",  size=2, unit="-"}, 
    {cmd="0x04", name="AT_RATE"                 , datatype="TYPE_INT",  size=2, unit="mA/10mW"}, 
    {cmd="0x05", name="AT_RATE_TIME2FULL"       , datatype="TYPE_UINT", size=2, unit="min"}, 
    {cmd="0x06", name="AT_RATE_TIME2EMPTY"      , datatype="TYPE_UINT", size=2, unit="min"}, 
    {cmd="0x07", name="AT_RATE_OK"              , datatype="TYPE_UINT", size=2, unit="-"}, 
    {cmd="0x08", name="TEMPERATURE"             , datatype="TYPE_UINT", size=2, unit="0.1°K"}, 
    {cmd="0x09", name="VOLTAGE"                 , datatype="TYPE_UINT", size=2, unit="mV"}, 
    {cmd="0x0A", name="CURRENT"                 , datatype="TYPE_INT",  size=2, unit="mA"}, 
    {cmd="0x0B", name="AVERAGE_CURRENT"         , datatype="TYPE_INT",  size=2, unit="mA"}, 
    {cmd="0x0C", name="MAX_ERROR"               , datatype="TYPE_UINT", size=1, unit="%"}, 
    {cmd="0x0D", name="RELATIVE_STATE_OF_CHARGE", datatype="TYPE_UINT", size=1, unit="%"}, 
    {cmd="0x0E", name="ABSOLUTE_STATE_OF_CHARGE", datatype="TYPE_UINT", size=1, unit="%"}, 
    {cmd="0x0F", name="REMAINING_CAPACITY"      , datatype="TYPE_UINT", size=2, unit="mAh/10mWh"}, 
    {cmd="0x10", name="FULL_CHARGE_CAPACITY"    , datatype="TYPE_UINT", size=2, unit="mAh/10mWh"}, 
    {cmd="0x11", name="RUN_TIME2EMPTY"          , datatype="TYPE_UINT", size=2, unit="min"}, 
    {cmd="0x12", name="AVERAGE_TIME2EMPTY"      , datatype="TYPE_UINT", size=2, unit="min"}, 
    {cmd="0x13", name="AVERAGE_TIME2FULL"       , datatype="TYPE_UINT", size=2, unit="min"}, 
    {cmd="0x14", name="CHARGING_CURRENT"        , datatype="TYPE_UINT", size=2, unit="mA"}, 
    {cmd="0x15", name="CHARGING_VOLTAGE"        , datatype="TYPE_UINT", size=2, unit="mV"}, 
    {cmd="0x16", name="BATTERY_STATUS"          , datatype="TYPE_UINT", size=2, unit="-"}, 
    {cmd="0x17", name="CYCLE_COUNT"             , datatype="TYPE_UINT", size=2, unit="-"}, 
    {cmd="0x18", name="DESIGN_CAPACITY"         , datatype="TYPE_UINT", size=2, unit="mAh/10mWh"}, 
    {cmd="0x19", name="DESIGN_VOLTAGE"          , datatype="TYPE_UINT", size=2, unit="mV"}, 
    {cmd="0x1A", name="SPECIFICATION_INFO"      , datatype="TYPE_UINT", size=2, unit="-"}, 
    {cmd="0x1B", name="MANUFACTURE_DATE"        , datatype="TYPE_UINT", size=2, unit="-"}, 
    {cmd="0x1C", name="SERIAL_NUMBER"           , datatype="TYPE_HEX",  size=2, unit="-"}, 
    {cmd="0x20", name="MANUFACTURER_NAME"       , datatype="TYPE_STRING", size=11+1, unit="ASCII"}, 
    {cmd="0x21", name="DEVICE_NAME"             , datatype="TYPE_STRING", size=7+1, unit="ASCII"}, 
    {cmd="0x22", name="DEVICE_CHEMISTRY"        , datatype="TYPE_STRING", size=4+1, unit="ASCII"}, 
    {cmd="0x23", name="MANUFACTURER_DATA"       , datatype="TYPE_STRING", size=14+1, unit="ASCII"}, 
    {cmd="0x2F", name="AUTHENTICATE"            , datatype="TYPE_STRING", size=20+1, unit="ASCII"}, 
    {cmd="0x3C", name="CELL_VOLTAGE4"           , datatype="TYPE_UINT", size=2, unit="mV"}, 
    {cmd="0x3D", name="CELL_VOLTAGE3"           , datatype="TYPE_UINT", size=2, unit="mV"}, 
    {cmd="0x3E", name="CELL_VOLTAGE2"           , datatype="TYPE_UINT", size=2, unit="mV"}, 
    {cmd="0x3F", name="CELL_VOLTAGE1"           , datatype="TYPE_UINT", size=2, unit="mV"}, 
}


bat_cmd_get = function(cmd)
	os.execute("echo "..cmd.." > /sys/devices/platform/battery/smbus_cmd")
	return tostring(read_attr_file("/sys/devices/platform/battery/smbus_cmd"))
end

log_bat_status = function (interval)
    local mt = {
        update = function(self)
			for i=1, table.getn(bat_cmd) do
				self[i] = bat_cmd[i].name.." : "..bat_cmd[i].cmd.." : "..bat_cmd_get(bat_cmd[i].cmd).." "..bat_cmd[i].unit
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
