
-- baseband_mode.lua
require "log"
require "baseband"
require "two_way_rf"

BaseBand_MODE = {
    title = "BaseBand Test",
    tips  = "Select the test item, move and space to select",
    multi_select_mode = true,
    init_env = function (t)
        init_global_env()
        --[[
        t.duration = 24 * 60 * 60
        defunc_battery_voltage_test(1)(t)
        --]]
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

        test_process_start = function (t) end,
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
            [1] = defunc_rx_desense_spkr_action(1),
        },

        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end,
        [1] = "Speaker test",

        test_process = {
            [1] = defunc_rx_desense_spkr.start(1),
        },
        stop_process = {
            [1] = defunc_rx_desense_spkr.stop(1),
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
            [1] = function (t)
                if t.select_status[2] then
                    t.select_status[2] = false
                end
            end,
            [2] = function (t)
                if t.select_status[1] then
                    t.select_status[1] = false
                end
            end,
            [3] = function (t)
                t.duration = t[3].duration
            end,
        },

        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end,
        [1] = "Accelerometer test",
        [2] = "Accelerometer selftest",
        [3] = defunc_select_duration(3),

        test_process = {
            [1] = defunc_accelerometer_test(1),
            [2] = defunc_accelerometer_selftest(2),
        },
        stop_process = {
            [1] = function (t) end,
            [2] = function (t) end,
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
    },
    [7] = {
        title = "Query Battery status",
        tips  = "Press * to start and # to end test",
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
            [3] = function (t)
                if t.select_status[3] then
                    global_bat_status_syslog_flag = true
                else
                    global_bat_status_syslog_flag = false
                end
            end,
        },

        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end,
        [1] = "Query Battery status",
        [2] = defunc_select_duration(2),
        [3] = "Enable syslog",

        test_process = {
            [1] = defunc_battery_voltage_test(1),
        },
        stop_process = {
            [1] = function (t) end,
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
        end,
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
            [2] = function (t)
                t.duration = t[2].duration
            end,
        },

        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end,
        [1] = "Query Device Temperature",
        [2] = defunc_select_duration(2),

        test_process = {
            [1] = defunc_query_device_temp_test(1),
        },
        stop_process = {
            [1] = function (t) end,
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
            [2] = function (t)
                t.duration = t[2].duration
            end,
        },

        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end,
        [1] = "Query Light Sensor",
        [2] = defunc_select_duration(2),

        test_process = {
            [1] = defunc_query_light_sensor_test(1),
        },
        stop_process = {
            [1] = function (t) end,
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
    },
    [10] = {
        title = "Query Volume Knob",
        tips  = "Press * to start and # to end test",
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
        [1] = "Query Volume Knob",
        [2] = defunc_select_duration(2),

        test_process = {
            [1] = defunc_query_volume_knob_test(1),
        },
        stop_process = {
            [1] = function (t) end,
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
    },
}

local device_type = device_type or read_config_mk_file("/etc/sconfig.mk", "Project")

if "g4_bba" == tostring(device_type) then
    BaseBand_MODE[table.getn(BaseBand_MODE)+1] = {
        title = "Vibrator Test",
        tips  = "Press * to start and # to end test",
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
    }

    BaseBand_MODE[table.getn(BaseBand_MODE)+1] = {
        title = "Accessory Test",
        tips  = "Press * to start and # to end test",
        multi_select_mode = true,
        new_main_menu = function (t)
            local m_sub = create_main_menu(t)
            m_sub:show()
            m_sub:action()
        end,
        action = function (t) end,
        [1] = "Accessory Test",
        test_process = {
            [1] = defunc_query_device_accessory_g4(1),
        },
        stop_process = {
            [1] = function (t) end,
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
    }
end
