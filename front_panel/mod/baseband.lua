
-- baseband.lua
require "log"
require "utility"
require "lnondsp"
require "keymap"

local device_type = device_type or read_config_mk_file("/etc/sconfig.mk", "Project")

defunc_disable_lcd = {
    start = function (list_index)
        return function (t)
            if t.select_status[list_index] then
                lnondsp.lcd_set_backlight_level(0)
                lnondsp.lcd_disable()
            end
        end
    end,

    stop = function (list_index)
        return function(t)
            lnondsp.lcd_enable()
            lnondsp.lcd_set_backlight_level(70)
        end
    end
}

defunc_lcd_display_static_image = function (list_index)
    return function (t)
        local pic_path = "/root/"..tostring(device_type).."_logo.dat"
        local width = 220
        local height = 176
        local r, msgid
        if t.select_status[list_index] then
            r, msgid = lnondsp.lcd_display_static_image(pic_path, width, height)
        end
    end
end

defunc_lcd_slide_show_test = {
    start = function (list_index)
        return function (t)
            local pic_path = "/usr/slideshow_dat_for_fcc"
            local range = 1  -- The time interval of showing two different images.

            if t.select_status[list_index] then
                lnondsp.lcd_slide_show_test_start(pic_path, range)
            else
                lnondsp.lcd_slide_show_test_stop()
            end
        end
    end,
    stop = function (list_index)
        return function (t)
            if t.select_status[list_index] then
                lnondsp.lcd_slide_show_test_stop()
            end
        end
    end
}

defunc_led_selftest = {
    start = function (list_index)
        return function (t)
            if t.select_status[list_index] then
                lnondsp.led_selftest_start()
            end
        end
    end,

    stop = function (list_index)
        return function (t)
            if t.select_status[list_index] then
                lnondsp.led_selftest_stop()
            end
        end
    end
}

defunc_select_duration = function (list_index)
    return {
        title = "Measure duration(s)",
        tips  = "Select Measure duration(s)",
        multi_select_mode = false,
        action_map = {
            [1] = function (t)
                t.duration =  30
            end,
            [2] = function (t)
                t.duration =  60
            end,
            [3] = function (t)
                t.duration =  240
            end,
            [4] = function (t)
                t.duration =  20 * 60 * 60
            end,
            [5] = get_para_func("duration", "duration(s)"),
        },
        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end,

        "30 s",
        "60 s",
        "240 s",
        "20 h",
        "Enter duration(s)",
    }
end

defunc_accelerometer_test = function (list_index)
    return function (t)
        if not t.select_status[list_index] then
            return;
        end

        if "number" ~= type(t.duration) then
            slog:win("the measure duration is not setting!")
            t.test_process_start_call = false
            return
        end

        os.execute("echo 1 > /sys/devices/virtual/sensors/motion_sensor/static_enable")
        local tcnt = time_counter()
        local mt = {
            title = "Accelerometer (+-4g)",
            tips = "Query Accelerometer",
            [1] = "x : y : z",
            update = function(self)
                self[2] = tostring(read_attr_file("/sys/devices/virtual/sensors/motion_sensor/dataxyz"))
                self.tips = "Accelerometer ("..tostring(tcnt()).." s)"
            end,
        }

        while tcnt() < tonumber(t.duration) do
            mt:update()
            create_main_menu(mt):show()
            posix.sleep(1)
        end

        os.execute("echo 0 > /sys/devices/virtual/sensors/motion_sensor/static_enable")
    end
end

defunc_accelerometer_selftest = function (list_index)
    return function (t)
        if not t.select_status[list_index] then
            return;
        end

        if "number" ~= type(t.duration) then
            slog:win("the measure duration is not setting!")
            t.test_process_start_call = false
            return
        end

        os.execute("echo 1 > /sys/devices/virtual/sensors/motion_sensor/selftest_enable")
        local tcnt = time_counter()
        local mt = {
            title = "Accel SelfTest (+-2g)",
            tips = "Query Accelerometer",
            [1] = "x : y : z",
            update = function(self)
                self[2] = tostring(read_attr_file("/sys/devices/virtual/sensors/motion_sensor/dataxyz"))
                self.tips = "Accelerometer SelfTest("..tostring(tcnt()).." s)"
            end,
        }

        while tcnt() < tonumber(t.duration) do
            mt:update()
            create_main_menu(mt):show()
            posix.sleep(1)
        end

        os.execute("echo 0 > /sys/devices/virtual/sensors/motion_sensor/selftest_enable")
    end
end

defunc_battery_voltage_test = function (list_index)

    return function (t)
        if "number" ~= type(t.duration) then
            slog:win("the measure duration is not setting!")
            t.test_process_start_call = false
            return
        end

        local tcnt = time_counter()
        local mt = {
            title = "battery test",
            tips = "battery test",
            update = function(self)
                self[1] = "external power-> "..bat_attr("external_power")
                self[2] = "status-> "..bat_attr("status")

                self.tips = "battery test ("..tostring(tcnt()).." s)"
            end,
            syslog = function(self)
                bat_status_tcnt = bat_status_tcnt or time_counter()
                if bat_status_tcnt() > 60 then
                    for k, v in ipairs(self) do
                        posix.syslog(posix.LOG_NOTICE, v)
                    end

                    posix.syslog(posix.LOG_NOTICE, self.tips)
                    bat_status_tcnt = nil
                end
            end
        }

        while tcnt() < tonumber(t.duration) do
            mt:update()
            create_main_menu(mt):show()
            if global_bat_status_syslog_flag then
                mt:syslog()
            end

            posix.sleep(1)
        end
    end
end

defunc_query_device_temp_test = function (list_index)
    return function (t)
        if "number" ~= type(t.duration) then
            slog:win("the measure duration is not setting!")
            t.test_process_start_call = false
            return
        end

        local tcnt = time_counter()
        local mt = {
            title = "Device Temperature",
            tips = "Query Device Temperature",
            update = function(self)
                self[1] = "status : "..tostring(read_attr_file("/sys/class/adc/pcb_temp/status"))
                self[2] = "vol (mV) : "..tostring(read_attr_file("/sys/class/adc/pcb_temp/curr_value"))
                self.tips = "Query Device Temperature ("..tostring(tcnt()).." s)"
            end,
        }

        while tcnt() < tonumber(t.duration) do
            mt:update()
            create_main_menu(mt):show()
            posix.sleep(1)
        end
    end
end

defunc_query_device_accessory_g4 = function (list_index)
    return function (t)
        if "number" ~= type(t.duration) then
            slog:win("the measure duration is not setting!")
            t.test_process_start_call = false
            return
        end

        local tcnt = time_counter()
        local mt = {
            title = "Device Accessory",
            tips = "Query Device Accessory",
            update = function(self)
                self[1] = "status : "..tostring(read_attr_file("/sys/devices/platform/accessory/chg_amp"))
                self.tips = "Query Device Accessory ("..tostring(tcnt()).." s)"
            end,
        }

        while tcnt() < tonumber(t.duration) do
            mt:update()
            create_main_menu(mt):show()
            posix.sleep(1)
        end
    end
end

defunc_query_light_sensor_test = function (list_index)
    return function (t)
        if "number" ~= type(t.duration) then
            slog:win("the measure duration is not setting!")
            t.test_process_start_call = false
            return
        end

        os.execute("echo 1 > /sys/class/adc/light_sensor/onoff")
        local tcnt = time_counter()
        local mt = {
            title = "Query Light Sensor",
            tips = "Query Light Sensor",
            update = function(self)
                self[1] = "status : "..tostring(read_attr_file("/sys/class/adc/light_sensor/status"))
                self[2] = "vol (mV) : "..tostring(read_attr_file("/sys/class/adc/light_sensor/curr_value"))
                self[3] = "level set : "..tostring(read_attr_file("/sys/class/adc/light_sensor/level"))
                self[3] = "upper : "..tostring(read_attr_file("/sys/class/adc/light_sensor/upper"))
                self[4] = "lower : "..tostring(read_attr_file("/sys/class/adc/light_sensor/lower"))
                self.tips = "Query Light Sensor ("..tostring(tcnt()).." s)"
            end,
        }

        while tcnt() < tonumber(t.duration) do
            mt:update()
            create_main_menu(mt):show()
            posix.sleep(1)
        end

        os.execute("echo 0 > /sys/class/adc/light_sensor/onoff")
    end
end

defunc_query_volume_knob_test = function (list_index)
    return function (t)
        if "number" ~= type(t.duration) then
            slog:win("the measure duration is not setting!")
            t.test_process_start_call = false
            return
        end

        local tcnt = time_counter()
        local mt = {
            title = "Query Volume Knob",
            tips = "Query Volume Knob",
            update = function(self)
                self[1] = "status : "..tostring(read_attr_file("/sys/class/adc/volume/status"))
                self[2] = "vol (mV) : "..tostring(read_attr_file("/sys/class/adc/volume/curr_value"))
                self[3] = "level set : "..tostring(read_attr_file("/sys/class/adc/volume/level"))
                self[4] = "upper : "..tostring(read_attr_file("/sys/class/adc/volume/upper"))
                self[5] = "lower : "..tostring(read_attr_file("/sys/class/adc/volume/lower"))
                self.tips = "Query Volume Knob ("..tostring(tcnt()).." s)"
            end,
        }

        while tcnt() < tonumber(t.duration) do
            mt:update()
            create_main_menu(mt):show()
            posix.sleep(1)
        end

    end
end

defunc_keypad_test = {
    start = function (list_index)
        return function (t)
            if t.select_status[list_index] then
                if "number" ~= type(t.duration) then
                   slog:win("the keypad measure duration is not setting")
                   return
                end
                lnondsp.keypad_enable()

                local tcnt = time_counter()
                local mt = {
                    title = "Keypad test",
                    tips = "keypad test",
                    [1] = "type : ",
                    [2] = "code : ",
                    [3] = "value : ",
                    [4] = "event channel : ",
                    [5] = "cur_channel : ",
                    update = function(self, wait_time)
                        if "number" ~= type(wait_time) then
                            slog:win("keypad wait time is not number(s)")
                            return
                        end

                        local time_cnt = time_counter()
                        while time_cnt() < tonumber(wait_time) do
                            local evt_index = lnondsp.get_evt_number()
                            local evt
                            if 0 == evt_index then
                                self[5] = "cur_channel : "..tostring(read_attr_file("/sys/devices/virtual/input/input0/cur_channel"))
                                posix.sleep(1)
                            else
                                evt = lnondsp.get_evt_item(1)
                                if not evt.ret then
                                    slog:win("get evt item("..tostring(evt_index)..") err: "..evt.errno..":"..evt.errmsg)
                                    return
                                end

                                local e_id = NONDSP_EVT:get_id(evt.evt, evt.evi)
                                if nil ~= e_id and e_id == "EVENT_REPORT" then
                                    self[1] = "type : "..tostring(evt.type)
                                    self[2] = "code : "..tostring(key_code:key_function(evt.code))
                                    self[3] = "value : "..tostring(key_value[evt.value])
                                    self[4] = "event channel : "..tostring(read_attr_file("/sys/devices/virtual/input/input0/cur_channel"))
                                    self.tips = "Keypad test ("..tostring(tcnt()).." s)"

                                    return
                                end
                            end
                        end
                    end,
                }

                while tcnt() < tonumber(t.duration) do
                    create_main_menu(mt):show()
                    mt:update(1)
                end

                t.test_process_start_call = false
            end
        end
    end,

    stop = function (list_index)
        return function (t)
            if t.select_status[list_index] then
                lnondsp.keypad_disable()
            end
        end
    end,
}

defunc_keypad_backlight_test = function (list_index)
    return function (t)
        if t.select_status[list_index] then
            lnondsp.keypad_set_backlight(t.backlight)
        end
    end
end

defunc_vibrator_test = {
    start = function (list_index)
        return function (t)
            if t.select_status[list_index] then
                lnondsp.vibrator_enable()
            end
        end
    end,

    stop = function (list_index)
        return function (t)
            if t.select_status[list_index] then
                lnondsp.vibrator_disable()
            end
        end
    end
}


defunc_query_sensor_test = function (list_index)
    return function (t)
        if "number" ~= type(t.duration) then
            slog:win("the measure duration is not setting!")
            t.test_process_start_call = false
            return
        end

        require "opkey"

        local dev = "/dev/input/event0"
        local k = openkey(dev, "nonblock")
        if k == nil then
            slog:win("Err: open "..dev)
            t.test_process_start_call = false
            return
        end

        -- os.execute("ecompass_daemon &")
        posix.sleep(1)
        os.execute("echo 400 > /sys/devices/virtual/sensors/motion_sensor/freefall_duration")
        os.execute("echo 1 > /sys/devices/virtual/sensors/motion_sensor/freefall_enable")
        os.execute("echo 1 > /sys/devices/virtual/sensors/motion_sensor/static_enable")
        os.execute("echo 1 > /sys/devices/virtual/sensors/motion_sensor/tilt_enable")
        os.execute("echo 1 > /sys/devices/virtual/sensors/ecompass/enable")
        os.execute("echo 1 > /sys/devices/virtual/sensors/pressure_sensor/enable")
        os.execute("echo 1 > /sys/devices/virtual/sensors/ecompass/calibration_enable")

        local tcnt = time_counter()
        local mt = {
            title = "Query Sensor",
            tips = "Query Sensor",
            update_event = function(self, index)
                local evts = k.readevts(lkey.event_size)
                if evts.ret then
                    for k, v in ipairs(evts) do
                        --note_in_window_delay("key code:value -> "..tostring(v.code)..":"..tostring(v.value), 2)

                        --[[
                        key code 150 : FREE_FALL_EVN
                        key code 151 : STATIC_EVN
                        key code 152 : TILT_EVN
                        key value: 2 -> press
                        --]]
                        if v.code == 150 then
                            self[index] = "Event: 150->FREE_FALL"
                        elseif v.code == 151 then
                            self[index] = "Event: 151->STATIC"
                        elseif v.code == 152 then
                            self[index] = "Event: 152->TILT"
                        end
                    end
                end
            end,
            update = function(self)
                self[1] = "accel dataxyz ->"
                self[2] = tostring(read_attr_file("/sys/devices/virtual/sensors/motion_sensor/dataxyz"))
                if nil == self[3] then
                    self[3] = "Event: nil"
                else
                    self:update_event(3)
                end
                self[4] = "Ecompass azimuth ->"
                self[5] = tostring(read_attr_file("/sys/devices/virtual/sensors/ecompass/azimuth"))
                self[6] = "Pressure : Temperature ->"
                self[7] = tostring(read_attr_file("/sys/devices/virtual/sensors/pressure_sensor/pressure")).." : "..tostring(read_attr_file("/sys/devices/virtual/sensors/pressure_sensor/temperature"))
                self.tips = "Query Sensor ("..tostring(tcnt()).." s)"
            end,
        }

        while tcnt() < tonumber(t.duration) do
            mt:update()
            create_main_menu(mt):show()
            posix.sleep(1)
        end

        k.close()
    end
end

