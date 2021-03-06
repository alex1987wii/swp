
require "menu_show"
require "lnondsp"
require "nondsp_event_info"
require "log"

--slog.win_note_en = true

bt_init = function()
    return {
        find_devices = function(t)
            local wait_menu = {
                title = "BT devices Scan",
                tips  = "Enable devices ..., plaease wait",
                multi_select_mode = false,
                [1] = "Enable BT ..."
            }

            create_main_menu(wait_menu):show()

            local r_d, r_d_errno = lnondsp.bt_disable()
            if not r_d then
                slog:win("find_devices bt_disable fail, return "..tostring(r_d_enno))
            end

            local r_en, r_enno = lnondsp.bt_enable_block(lnondsp.BT_HIGH_SPEED)
            if not r_en then
                slog:win("find_devices bt_enable_block fail, return "..tostring(r_enno))
                return nil
            end

            wait_menu.tips  = "scanning devices ..., plaease wait"
            wait_menu[1] = "Scanning ..."
            create_main_menu(wait_menu):show()
            local r_scan = lnondsp.bt_scan_block()
            posix.sleep(1)
            local ev = lnondsp.get_evt_item(lnondsp.get_evt_number())
            local e_id = NONDSP_EVT:get_id(ev.evt, ev.evi)
            if e_id ~= "SCAN_ID_NAME" then
                slog:win("find_devices, can not get the event SCAN_ID_NAME")
                return nil
            end
            slog:notice("find devices "..tostring(ev.ret)..":"..tostring(ev.evt)..":"..tostring(ev.evi)..":"..tostring(ev.count))

            if (ev.count > 0) and (ev.count < 10) then
                t.devices = {}
                t.devices.count = ev.count
                for i=1, ev.count do
                    t.devices[i] = {}
                    t.devices[i].id = ev.id[i]
                    t.devices[i].name = ev.name[i]
                    slog:notice("BT dev["..i.."]: "..tostring(ev.name[i]).." : "..tostring(ev.id[i]))
                end
                return t.devices
            else
                slog:win("find_devices error, scan devices(count:"..tostring(ev.count)..")")
                return nil
            end
        end,

        get_devices_table = function(t)
            if (nil == t.devices) or (nil == t.devices.count) or (t.devices.count < 1) then
                slog:err("t.devices or t.devices.count null")
                return nil
            end

            t.menu_tab = t.menu_tab or {
                title = "BT devices",
                tips  = "select and keyin ENTER to connect device, * to scan again",
                multi_select_mode = false,
            }

            t.menu_tab.devices_connect_status = {}
            t.menu_tab.devices_count = t.devices.count
            t.menu_tab.dev_id = {}
            for d=1, t.devices.count do
                t.menu_tab[d] = t.devices[d].name
                t.menu_tab.dev_id[d] = t.devices[d].id
                t.menu_tab.devices_connect_status[d] = false
            end

            t.menu_tab.new_main_menu = function(tab)
                local m_sub = create_main_menu(tab)
                m_sub:show()
                m_sub:action()
            end

            t.menu_tab.action = function(tab)
                for i=1, tab.devices_count do
                    if tab.devices_connect_status[i] then
                        lnondsp.bt_disconnect_sco(tab.dev_id[i])
                        tab.devices_connect_status[i] = false
                    end
                end

                if tab.select_status[tab.select_index] then
                     --slog:win("lnondsp.bt_establish_sco_block("..tab.dev_id[tab.select_index]..")")
                    lnondsp.bt_establish_sco_block(tab.dev_id[tab.select_index])
                    tab.devices_connect_status[tab.select_index] = true
                    --tab.test_process_start_call = true
                    tab.force_test_process_start_call = true
                end
            end

            t.menu_tab.test_process_start = function(tab)
                switch_self_refresh(true)
                tab.test_process_start_call = false
                tab.force_test_process_start_call = true
                g_bt = g_bt or bt_init()
                if nil == g_bt then
                    slog:win("g_bt fail, please check the error msg")
                    return false
                end

                g_bt:find_devices()

                tab.devices_count = g_bt.devices.count
                tab.dev_id = {}
                tab.devices_connect_status = {}
                tab.select_status = {}
                for d=1, g_bt.devices.count do
                    tab[d] = g_bt.devices[d].name
                    tab.dev_id[d] = g_bt.devices[d].id
                    tab.devices_connect_status[d] = false
                    tab.select_status[d] = false
                end
                tab.select_index = 1
                tab[g_bt.devices.count + 1] = nil

            end

            t.menu_tab.test_process_stop = function(tab) 
                --slog:win("test_process_stop call")
                for i=1, tab.devices_count do
                    if tab.devices_connect_status[i] then
                        lnondsp.bt_disconnect_sco(tab.dev_id[i])
                    end
                    tab.devices_connect_status[i] = false
                    tab.select_status[i] = false
                end
                tab.force_test_process_start_call = false
            end

            return t.menu_tab
        end,

        disable = function(t)
            lnondsp.bt_disable()
        end
    }
end

defunc_bt_rftest_transmitter = {
    start = function (list_index)
        return function (t)
            if not t.select_status[list_index] then
                t.test_process_start_call = false
                return
            end

            if "string" ~= type(t.rftest_type) or ("TXDATA1" ~= t.rftest_type and "TXDATA2" ~= t.rftest_type) then
                slog:win("bt_rftest_transmitter_start rftest_type error")
                t.test_process_start_call = false
                return false
            end
            
            if "TXDATA1" == t.rftest_type then
                if nil == t.freq or "number" ~= type(t.freq) or 0 == t.freq then
                    slog:win("bt_rftest_transmitter_start freq error")
                    t.test_process_start_call = false
                    return false
                end
            end
            
            if nil == t.data_rate or "string" ~= type(t.data_rate) then
                slog:win("bt_rftest_transmitter_start data_rate error")
                t.test_process_start_call = false
                return false
            end

            local r, msgid = lnondsp.bt_rftest_transmitter_start(t.rftest_type, t.freq, t.data_rate)
            if not r then
                slog:win("call bt_rftest_transmitter_start fail! errcode: "..tostring(msgid))
                t.test_process_start_call = false
            end
        end
    end,

    stop = function (list_index)
        return function (t)
            if t.select_status[list_index] then
                lnondsp.bt_rftest_transmitter_stop()
            end
        end
    end
}

defunc_enable_bt = function(list_index)
    return function(t)
        if "nil" == type(t[list_index]) then
            slog:err("bt device find item nil")
            t[list_index] = "Find Bt Devices"
        elseif "string" == type(t[list_index]) then
            g_bt = g_bt or bt_init()
            if nil == g_bt then
                slog:win("bt enable fail, please check the error msg")
                return false
            end

            g_bt:find_devices()
            local bt_menu = g_bt:get_devices_table()
            if nil == bt_menu then
                slog:err("bt:get_devices_table, can not scan devices")
                return false
            end

            t[list_index] = bt_menu
            local m = create_main_menu(t[list_index])
            m:show()
            m:action()
        end
    end
end

def_disable_bt = function()
    g_bt = g_bt or bt_init()
    if nil == g_bt then
        slog:win("bt enable fail, please check the error msg")
        return false
    end

    g_bt:disable()
end

