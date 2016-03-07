
-- manufacture_mode.lua
require "log"
require "baseband"
require "two_way_rf"

MFC_MODE = {
    title = "Manufacture Test",
    tips  = "Select the test item, move and space to select",
    multi_select_mode = false,
    init_env = function (t)
        init_global_env()
    end,
    action_map = {
        [1] = function (t) end,
        [2] = function (t) end,
        [3] = function (t) end,
        [4] = function (t) end,
    },
    action = function (t)
        if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
            t.action_map[t.select_index](t)
        end
    end,

    [1] = {
        title = "1. LCD Slideshow test",
        tips  = "Press SF3 to start and SF4 to end test",
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

        test_process = {
            [1] = defunc_lcd_slide_show_test.start(1),
        },
        stop_process = {
            [1] = defunc_lcd_slide_show_test.stop(1),
        },
        test_process_start = function (t)
            for i=1, table.getn(t) do
                if "function" == type(t.test_process[i]) then
                    t.test_process[i](t)
                end
            end
        end,
        test_process_stop = function (t)
            for i=1, table.getn(t) do
                if "function" == type(t.stop_process[i]) then
                    t.stop_process[i](t)
                end
            end
        end
    },
    [2] = {
        title = "2. LED/Keypad BL test",
        tips  = "Press SF3 to start and SF4 to end test",
        multi_select_mode = true,
        new_main_menu = function (t)
            local m_sub = create_main_menu(t)
            m_sub:show()
            m_sub:action()
        end,
        action_map = {
            [1] = function (t)  end,
            [2] = function (t)
                t.backlight = t[2].backlight
            end,
        },

        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end,
        [1] = "LED test",
        [2] = {
            title = "Keypad BL test",
            tips  = "Keypad BL ON/OFF",
            multi_select_mode = false,

            action = function (t)
                local bl_g = {true, false}
                t.backlight = bl_g[t.select_index]
            end,

            "ON",
            "OFF",
        },

        test_process = {
            [1] = defunc_led_selftest.start(1),
            [2] = defunc_keypad_backlight_test(2)
        },
        stop_process = {
            [1] = defunc_led_selftest.stop(1),
        },
        test_process_start = function (t)
            for i=1, table.getn(t) do
                if "function" == type(t.test_process[i]) then
                    t.test_process[i](t)
                end
            end
        end,
        test_process_stop = function (t)
            for i=1, table.getn(t) do
                if "function" == type(t.stop_process[i]) then
                    t.stop_process[i](t)
                end
            end
        end
    },
    [3] = {
        title = "3. Vibrator Test",
        tips  = "Press SF3 to start and SF4 to end test",
        multi_select_mode = true,
        new_main_menu = function (t)
            local m_sub = create_main_menu(t)
            m_sub:show()
            m_sub:action()
        end,
        action = function (t) end,
        [1] = "Vibrator Test",
        test_process = {
            [1] = defunc_vibrator_test.start(1),
        },
        stop_process = {
            [1] = defunc_vibrator_test.stop(1),
        },

        test_process_start = function (t)
            switch_self_refresh(true)
            for i=1, table.getn(t) do
                if "function" == type(t.test_process[i]) then
                    t.test_process[i](t)
                end
            end
        end,
        test_process_stop = function (t)
            for i=1, table.getn(t) do
                if "function" == type(t.stop_process[i]) then
                    t.stop_process[i](t)
                end
            end
        end
    },
    [4] = {
        title = "4. Button test",
        tips  = "Press SF3 to start and SF4 to end test",
        multi_select_mode = true,
        new_main_menu = function (t)
            local m_sub = create_main_menu(t)
            m_sub:show()
            m_sub:action()
        end,
        action_map = {
            [1] = function (t)  end,
            [2] = function (t)
                t.duration = t[2].duration
            end,
        },

        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end,
        [1] = "Button test",
        [2] = defunc_select_duration(2),

        test_process = {
            [1] = defunc_keypad_test.start(1),
        },
        stop_process = {
            [1] = defunc_keypad_test.stop(1),
        },
        test_process_start = function (t)
            switch_self_refresh(true)
            for i=1, table.getn(t) do
                if "function" == type(t.test_process[i]) then
                    t.test_process[i](t)
                end
            end
            t.test_process_start_call = false
        end,
        test_process_stop = function (t)
            for i=1, table.getn(t) do
                if "function" == type(t.stop_process[i]) then
                    t.stop_process[i](t)
                end
            end
        end
    }
}
