-- lnondsp.lua 

require "log"

local info = (lua_log or lua_log.i) or print
lnondsp = {
    register_callbacks = function() 
        info("lnondsp", "register_callbacks")
    end, 
    get_evt_number = function()
        info("lnondsp", "get_evt_number")
        return 1
    end, 
    get_evt_item = function()
        info("lnondsp", "get_evt_item")
        return {}
    end, 
    gps_enable = function(...)
        local argstr = ""
        info("gps_enable", "1")
        for k=1, arg.n do
            info("gps_enable", "1-1 "..k)
            argstr = argstr..arg[k]..", "
        end
        info("gps_enable", "type "..type(argstr).." "..(tostring(argstr) or " nil"))
    end, 
    gps_disable = function(...)
        local argstr = ""
        for k=1, arg.n do
            argstr = argstr..arg[k]..", "
        end
        info("gps_disable", "type "..type(argstr).." "..(tostring(argstr) or " nil"))
    end, 
    lcd_enable = function(...)
        local argstr = ""
        for k=1, arg.n do
            argstr = argstr..arg[k]..", "
        end
        info("lcd_enable", "type "..type(argstr).." "..(tostring(argstr) or " nil"))
    end, 
    lcd_disable = function(...)
        local argstr = ""
        for k=1, arg.n do
            argstr = argstr..arg[k]..", "
        end
        info("lcd_disable", "type "..type(argstr).." "..(tostring(argstr) or " nil"))
    end, 
    lcd_display_static_image = function(...)
        local argstr = ""
        info("lcd_display_static_image", "1")
        for k=1, arg.n do
            info("lcd_display_static_image", "1-"..k)
            argstr = argstr..arg[k]..", "
        end
        info("lcd_display_static_image", "type "..type(argstr).." "..(tostring(argstr) or " nil"))
    end, 
    lcd_slide_show_test_start = function(...)
        local argstr = ""
        for k=1, arg.n do
            argstr = argstr..arg[k]..", "
        end
        info("lcd_slide_show_test_start", "type "..type(argstr).." "..(tostring(argstr) or " nil"))
    end, 
    lcd_slide_show_test_stop = function(...)
        local argstr = ""
        for k=1, arg.n do
            argstr = argstr..arg[k]..", "
        end
        info("lcd_slide_show_test_stop", "type "..type(argstr).." "..(tostring(argstr) or " nil"))
    end, 
    led_selftest_start = function(...)
        local argstr = ""
        for k=1, arg.n do
            argstr = argstr..arg[k]..", "
        end
        info("led_selftest_start", "type "..type(argstr).." "..(tostring(argstr) or " nil"))
    end, 
    led_selftest_stop = function(...)
        local argstr = ""
        for k=1, arg.n do
            argstr = argstr..arg[k]..", "
        end
        info("led_selftest_stop", "type "..type(argstr).." "..(tostring(argstr) or " nil")) 
    end, 
}

return lnondsp
