
-- baseband.lua 
require "log"
require "lnondsp"

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
            local r, msgid
            if t.select_status[list_index] then
                r, msgid = lnondsp.lcd_slide_show_test_start(pic_path, range)
            else
                r, msgid = lnondsp.lcd_slide_show_test_stop()
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
            local r, msgid
            if t.select_status[list_index] then
                r, msgid = lnondsp.led_selftest_start()
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

defunc_vibrator_test = {
    start = function (list_index)
        return function (t)
            local r, msgid
            if t.select_status[list_index] then
                r, msgid = lnondsp.vibrator_enable()
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


BaseBand_MODE = {
    title = "BaseBand Test", 
    tips  = "Select the test item, move and space to select", 
    multi_select_mode = true, 
    init_env = function (t)
        init_global_env()
    end, 
    action_map = {
        [1] = function (t) end, 
        [2] = function (t) end, 
        [3] = function (t) end, 
        [4] = function (t) end, 
        [5] = function (t) end, 
    }, 
    action = function (t)
        if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
            t.action_map[t.select_index](t)
        end
    end, 

    [1] = {
        title = "Battery lift test", 
        tips  = "Press * to start and # to end test", 
        multi_select_mode = true, 
        new_main_menu = function (t)
            local m_sub = create_main_menu(t)
            m_sub:show()
            m_sub:action()
        end, 
        action_map = {
            [1] = function (t)  end, 
        }, 

        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end, 
        [1] = "Battery lift test", 
        
        test_process_start = function (t) 

        end, 
        test_process_stop = function (t) end
    }, 
    [2] = {
        title = "Speaker test", 
        tips  = "Press * to start and # to end test", 
        multi_select_mode = true, 
        new_main_menu = function (t)
            local m_sub = create_main_menu(t)
            m_sub:show()
            m_sub:action()
        end, 
        action_map = {
            [1] = function (t)  end, 
        }, 

        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end, 
        [1] = "Speaker test", 
        
        test_process_start = function (t) end, 
        test_process_stop = function (t) end
    }, 
    [3] = {
        title = "LCD Slideshow test", 
        tips  = "Press * to start and # to end test", 
        multi_select_mode = true, 
        new_main_menu = function (t)
            local m_sub = create_main_menu(t)
            m_sub:show()
            m_sub:action()
        end, 
        action_map = {
            [1] = function (t)  end, 
        }, 

        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end, 
        [1] = "LCD Slideshow test", 
        
        test_process_start = function (t) end, 
        test_process_stop = function (t) end
    },  
    [4] = {
        title = "LED/Keypad BL test", 
        tips  = "Press * to start and # to end test", 
        multi_select_mode = true, 
        new_main_menu = function (t)
            local m_sub = create_main_menu(t)
            m_sub:show()
            m_sub:action()
        end, 
        action_map = {
            [1] = function (t)  end, 
            [2] = function (t)  end, 
        }, 

        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end, 
        [1] = "LED test", 
        [2] = "Keypad BL test", 
        
        test_process_start = function (t) end, 
        test_process_stop = function (t) end
    },  
    [5] = {
        title = "Button test", 
        tips  = "Press * to start and # to end test", 
        multi_select_mode = true, 
        new_main_menu = function (t)
            local m_sub = create_main_menu(t)
            m_sub:show()
            m_sub:action()
        end, 
        action_map = {
            [1] = function (t)  end, 
        }, 

        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end, 
        [1] = "Button test", 
        
        test_process_start = function (t) end, 
        test_process_stop = function (t) end
    },  
    [6] = {
        title = "Accelerometer test", 
        tips  = "Press * to start and # to end test", 
        multi_select_mode = true, 
        new_main_menu = function (t)
            local m_sub = create_main_menu(t)
            m_sub:show()
            m_sub:action()
        end, 
        action_map = {
            [1] = function (t)  end, 
        }, 

        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end, 
        [1] = "Accelerometer test", 
        
        test_process_start = function (t) end, 
        test_process_stop = function (t) end
    },  
    [7] = {
        title = "Query Battery Voltage", 
        tips  = "Press * to start and # to end test", 
        multi_select_mode = true, 
        new_main_menu = function (t)
            local m_sub = create_main_menu(t)
            m_sub:show()
            m_sub:action()
        end, 
        action_map = {
            [1] = function (t)  end, 
        }, 

        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end, 
        [1] = "Query Battery Voltage", 
        
        test_process_start = function (t)
            switch_self_refresh(true)
            
            local mt = {
                title = "battery test", 
                tips = "battery test", 
                [1] = "curr : "..tostring(read_attr_file("/sys/devices/platform/battery/charge_current")), 
                [2] = "event : "..tostring(read_attr_file("/sys/devices/platform/battery/charger_event")), 
                [3] = "status : "..tostring(read_attr_file("/sys/devices/platform/battery/status")), 
                update = function(self)
                    self[1] = "curr : "..tostring(read_attr_file("/sys/devices/platform/battery/charge_current")) 
                    self[2] = "event : "..tostring(read_attr_file("/sys/devices/platform/battery/charger_event")) 
                    self[3] = "status : "..tostring(read_attr_file("/sys/devices/platform/battery/status")) 
                end, 
            }
            
            while true do
                create_main_menu(mt):show()
                posix.sleep(1)
                mt:update()
            end
        
        end, 
        test_process_stop = function (t) end
    },   
    [8] = {
        title = "Query Device Temperature", 
        tips  = "Press * to start and # to end test", 
        multi_select_mode = true, 
        new_main_menu = function (t)
            local m_sub = create_main_menu(t)
            m_sub:show()
            m_sub:action()
        end, 
        action_map = {
            [1] = function (t)  end, 
        }, 

        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end, 
        [1] = "Query Device Temperature", 
        
        test_process_start = function (t) end, 
        test_process_stop = function (t) end
    },  
    [9] = {
        title = "Query Light Sensor", 
        tips  = "Press * to start and # to end test", 
        multi_select_mode = true, 
        new_main_menu = function (t)
            local m_sub = create_main_menu(t)
            m_sub:show()
            m_sub:action()
        end, 
        action_map = {
            [1] = function (t)  end, 
        }, 

        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end, 
        [1] = "Query Light Sensor", 
        
        test_process_start = function (t) end, 
        test_process_stop = function (t) end
    },  
}
