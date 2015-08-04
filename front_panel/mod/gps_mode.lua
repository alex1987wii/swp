-- gps_mode.lua
require "log"
require "gps"

require "two_way_rf"
require "baseband"

GPS_MODE = {
    title = "GPS Test",
    tips  = "Press * to start. The test will stop automatically",
    multi_select_mode = true,
    init_env = function (t)
        init_global_env()
        gpslog = gpslog or modlog("gps", gpslogfullpath)

    end,
    action_map = {
        [1] = function (t)
            t.restart_mode = t[1].restart_mode
            t.measurement_num = t[1].measurement_num
            t.select_status[2] = false
        end,
        [2] = function (t)
            t.svid = t[2].svid
            t.trancking_time = t[2].trancking_time
            t.interval = t[2].interval
            t.measurement_num = t[2].measurement_num
            t.select_status[1] = false
        end,

    },
    action = function (t)
        if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
            t.action_map[t.select_index](t)
        end
    end,
    [1] = {
        --[[ display to user'acquiring GPS signal'.Once acquired display to the user
            the 'latitude and longitude' of the fixes
        --]]
        title = "Functional",
        tips  = "",
        multi_select_mode = true,
        new_main_menu = function (t)
            local m_sub = create_main_menu(t)
            m_sub:show()
            m_sub:action()
        end,
        action_map = {
            [1] = function (t)
                t.restart_mode = t[1].restart_mode
            end,
            [2] = get_para_func("measurement_num", "Num of measurements"),
        },

        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end,
        [1] = {
            title = "Restart mode",
            tips  = "Select restart mode",
            multi_select_mode = false,
            action = function (t)
                local restart_mode_t = {"cold_start", "warm_start", "hot_start"}
                t.restart_mode = restart_mode_t[t.select_index]
                slog:notice("set restart mode: "..tostring(t.restart_mode))
            end,
            "cold start mode",
            "warn start mode",
            "hot  start mode",
        },
        [2] = "Num of measurements",

        test_process_start = defunc_gps_functional_test.start(1),
        test_process_stop = defunc_gps_functional_test.stop(1),
    },
    [2] = {
        title = "Hardware",
        tips  = "Hardware test",
        multi_select_mode = true,
        new_main_menu = function (t)
            local m_sub = create_main_menu(t)
            m_sub:show()
            m_sub:action()
        end,
        action_map = {
            [1] = get_para_func("svid", "SVID"),
            [2] = get_para_func("trancking_time", "Tracking time"),
            [3] = get_para_func("interval", "Measurement interval"),
            [4] = get_para_func("measurement_num", "Num of measurements"),
        },
        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end,
        [1] = "SVID",
        [2] = "Tracking time",
        [3] = "Measurement interval",
        [4] = "Num of measurements",

        test_process_start = defunc_gps_hw_test.start(1),
        test_process_stop = defunc_gps_hw_test.stop(1),
    },

    test_process = {
        [1] = defunc_gps_functional_test.start(1),
        [2] = defunc_gps_hw_test.start(2),
    },
    stop_process = {
        [1] = function (t) end,
        [2] = function (t) end,
    },
    test_process_start = function (t)
        t.report = {}
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
    end,
}
