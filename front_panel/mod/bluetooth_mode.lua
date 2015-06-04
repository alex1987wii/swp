
-- bluetooth_mode.lua
require "log"
require "bluetooth"
require "gps"
require "two_way_rf"

Bluetooth_MODE = {
    title = "Bluetooth",
    tips  = "Press * to start and # to end test",
    multi_select_mode = true,
    init_env = function (t)
        init_global_env()
    end,
    action_map = {
        [1] = defunc_enable_bt(1),
        [2] = function (t)
            t.freq = t[2].freq
            t.data_rate = t[2].data_rate
            t.select_status[1] = false
        end,
    },
    action = function (t)
        if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
            t.action_map[t.select_index](t)
        end
    end,
    [1] = "Find BT Device",
    [2] = {
        title = "Hardware test",
        tips  = "Hardware test",
        multi_select_mode = true,

        action = function (t)
            t.freq = t[1].freq
            t.data_rate = t[2].data_rate
        end,
        [1] = {
            title = "Frequency",
            tips  = "Select Frequency",
            multi_select_mode = false,
            action = function (t)
                local freq_g = {2402, 2441, 2480}
                t.freq = freq_g[t.select_index]
            end,
            "2402 MHz",
            "2441 MHz",
            "2480 MHz",
        },
        [2] = {
            title = "Data Rate",
            tips  = "Select Data Rate(Packet Type)",
            multi_select_mode = false,
            action = function (t)
                t.data_rate = t[t.select_index].data_rate
            end,
            [1] = {
                title = "Basic Data Rate",
                tips  = "Select Basic Data Rate",
                multi_select_mode = false,
                action = function (t)
                    t.data_rate = t[t.select_index]
                end,
                "DH1",
                "DH3",
                "DH5",
            },
            [2] = {
                title = "Enhanced Data Rate",
                tips  = "Select Enhanced Data Rate(Packet Type)",
                multi_select_mode = false,
                action = function (t)
                    t.data_rate = t[t.select_index]
                end,
                "2-DH1",
                "2-DH5",
                "3-DH1",
                "3-DH5",
            },
        }
    },

    test_process = {
        [1] = function (t) end,
        [2] = defunc_bt_txdata1_transmitter.start(2),

    },
    stop_process = {
        [1] = function (t) end,
        [2] = defunc_bt_txdata1_transmitter.stop(2),

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

