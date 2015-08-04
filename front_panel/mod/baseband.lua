
-- baseband.lua 
require "log"
require "utility"
require "lnondsp"

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
                t.duration =  60
            end, 
            [2] = function (t)
                t.duration =  240
            end, 
            [3] = function (t)
                t.duration =  1000
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

        "60 s", 
        "240 s", 
        "1000 s", 
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
    if "g4_bba" == device_type then
        -- 100% -> 0% 
        capacity_percent_vols_table_tmp = {
            -- 1800mAH 20 
            ["1800mAH"] = {
                4351, 4330, 4313, 4298, 4286, 4275, 4264, 4252, 4241, 4230, 
                4219, 4209, 4198, 4188, 4177, 4167, 4156, 4146, 4135, 4125, 
                4114, 4104, 4094, 4084, 4077, 4071, 4063, 4053, 4039, 4022, 
                4007, 3994, 3984, 3975, 3968, 3962, 3956, 3950, 3943, 3934, 
                3926, 3917, 3909, 3901, 3894, 3887, 3881, 3875, 3869, 3863, 
                3857, 3852, 3847, 3842, 3837, 3833, 3828, 3824, 3820, 3816, 
                3811, 3807, 3804, 3800, 3797, 3793, 3789, 3786, 3783, 3780, 
                3777, 3775, 3772, 3769, 3766, 3764, 3761, 3758, 3754, 3751, 
                3747, 3742, 3736, 3730, 3724, 3717, 3710, 3703, 3700, 3696, 
                3693, 3689, 3685, 3680, 3671, 3653, 3624, 3585, 3533, 3461, 
                3351}, 
            --
            -- 2800mAH 20
            ["2800mAH"] = {
                4340, 4310, 4294, 4277, 4264, 4251, 4240, 4229, 4217, 4206, 
                4195, 4184, 4173, 4163, 4151, 4141, 4130, 4120, 4110, 4098, 
                4089, 4078, 4071, 4064, 4057, 4047, 4032, 4014, 3999, 3987, 
                3976, 3969, 3962, 3956, 3950, 3944, 3937, 3929, 3921, 3913, 
                3905, 3897, 3889, 3881, 3875, 3868, 3862, 3855, 3850, 3844, 
                3840, 3835, 3830, 3826, 3821, 3817, 3813, 3809, 3805, 3802, 
                3798, 3795, 3792, 3789, 3786, 3783, 3780, 3778, 3775, 3773, 
                3770, 3768, 3766, 3764, 3762, 3760, 3757, 3755, 3751, 3748, 
                3744, 3740, 3734, 3728, 3721, 3714, 3706, 3698, 3695, 3692, 
                3690, 3688, 3686, 3682, 3676, 3664, 3632, 3587, 3513, 3421, 
                3240}
            --]]
            }
        capacity_percent_vols_table = {["1800mAH"] = {}, ["2800mAH"] = {}}

        -- 0% -> 100% 
        for i=1, 101 do
            capacity_percent_vols_table["1800mAH"][i] = capacity_percent_vols_table_tmp["1800mAH"][101 - i]
            capacity_percent_vols_table["2800mAH"][i] = capacity_percent_vols_table_tmp["2800mAH"][101 - i]
        end

        T2R_tab = {
            ["1800mAH"] = {
                T = {0, 100, 200, 300, 400, 500}, 
                R = {0.53, 0.35, 0.25, 0.20, 0.16, 0.16}
            }, 
            ["2800mAH"] = {
                T = {0, 100, 200, 300, 400, 500}, 
                R = {0.36, 0.24, 0.18, 0.14, 0.14, 0.17}
            }
        }

        Temp2Rzint = function (temp, TR_tab)
            local g_t = TR_tab.T  -- unit: 0.1dec 
            local g_r = TR_tab.R
            
            for i=1, table.getn(g_t) do
                if temp <= g_t[i] then
                    if 1 == i then
                        return g_r[i]
                    else
                        return (g_r[i-1] + (g_r[i] - g_r[i-1]) * (temp - g_t[i-1]) / (g_t[i] - g_t[i-1]))
                    end
                end
            end
            
            return g_r[6]
        end

        get_bat_status = function ()
            local status = read_attr_file("/sys/devices/platform/battery/status")
            local status_tab = get_item_from_formats(status)
            return {
                chg_status = status_tab[2], 
                vbat = tonumber(read_attr_file("/sys/devices/platform/battery/vbat")), 
                temp = tonumber(status_tab[4]), 
                isen = tonumber(read_attr_file("/sys/devices/platform/battery/charge_current")), 
                isys = 180, 
                Rzint = {
                    ["1800mAH"]=Temp2Rzint(tonumber(status_tab[4]), T2R_tab["1800mAH"]), 
                    ["2800mAH"]=Temp2Rzint(tonumber(status_tab[4]), T2R_tab["2800mAH"])}
            }
        end

        vc_cal = function (stat_tab, battype)
            return stat_tab.vbat - ((0 - stat_tab.isen) - stat_tab.isys) * stat_tab.Rzint[battype]
        end

        vol2percent = function (vol, vols_table)
            for p, v in ipairs(vols_table) do
                if vol < v then
                    return (p - 1)
                end
            end
            
            return 100
        end

        capacity_cal = function (vol_cal, vols_table)
            return vol2percent(vol_cal, vols_table)
        end
        
        get_abb_reg = function (reg)
            return function()
                os.execute("echo "..reg.." >  /sys/devices/virtual/validate_ad6855/validate_ad6855/address")
                return read_attr_file("/sys/devices/virtual/validate_ad6855/validate_ad6855/data")
            end
        end
    end
    
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
                self[1] = "event : "..tostring(read_attr_file("/sys/devices/platform/battery/charger_event")) 
                if "g4_bba" == device_type then
                    self[2] = "curr : "..tostring(read_attr_file("/sys/devices/platform/battery/charge_current")) 
                    self[3] = "vchg : "..tostring(read_attr_file("/sys/devices/platform/battery/vchg")) 
                    self[4] = "abb reg 0x36 : "..tostring(get_abb_reg("0x36")())
                    self[5] = "abb reg 0x11 : "..tostring(get_abb_reg("0x11")())
                    self[6] = "abb reg 0x37 : "..tostring(get_abb_reg("0x37")())
                    self[7] = "abb reg 0x38 : "..tostring(get_abb_reg("0x38")())
                    self[8] = "abb reg 0x3A : "..tostring(get_abb_reg("0x3A")())
                    self[9] = "abb reg 0x3B : "..tostring(get_abb_reg("0x3B")())
                    self[10] = "abb reg 0x3C : "..tostring(get_abb_reg("0x3C")())
                    self[11] = "abb reg 0x3D : "..tostring(get_abb_reg("0x3D")())
                    self[12] = "intstat      : "..tostring(read_attr_file("/sys/devices/platform/battery/charge_detect")) 
                    local stat_tab = get_bat_status()
                    local vol_cal = {
                        ["1800mAH"] = math.floor(vc_cal(stat_tab, "1800mAH")), 
                        ["2800mAH"] = math.floor(vc_cal(stat_tab, "2800mAH"))}
                    local capa_percent = {
                        ["1800mAH"] = capacity_cal(vol_cal["1800mAH"], capacity_percent_vols_table["1800mAH"]), 
                        ["2800mAH"] = capacity_cal(vol_cal["2800mAH"], capacity_percent_vols_table["2800mAH"])}
                    self[13] = "vbat:1800|2800: "..stat_tab.vbat..":"..vol_cal["1800mAH"].."|"..vol_cal["2800mAH"]
                    self[14] = "bat capacity : "..capa_percent["1800mAH"].." | "..capa_percent["2800mAH"]
                    self[15] = "status : "..tostring(read_attr_file("/sys/devices/platform/battery/status")) 
                else
                    self[2] = "status : "..tostring(read_attr_file("/sys/devices/platform/battery/status")) 
                end
                
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
                self[3] = "upper : "..tostring(read_attr_file("/sys/class/adc/volume/upper"))
                self[4] = "lower : "..tostring(read_attr_file("/sys/class/adc/volume/lower"))
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
                                    self[2] = "code : "..tostring(evt.code) 
                                    self[3] = "value : "..tostring(evt.value) 
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
    end
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
