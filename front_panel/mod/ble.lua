
require "menu_show"
require "lnondsp"
require "nondsp_event_info"
require "log"
require "utility"

--slog.win_note_en = true

ble_init = function()

    local r_hw, hw_state = lnondsp.ble_get_hw_state()
    if not r_hw then
        slog:win("ble_init: ble_get_hw_state fail, return "..tostring(hw_state))
        return nil
    end

    if hw_state == 0 then
        slog:win("ble_init: ble module not install.")
        return nil
    end

    return {
        power_on= function(t)
            local wait_menu = {
                title = "BLE INIT",
                tips  = "Power On BLE ..., plaease wait",
                multi_select_mode = false,
                [1] = "Power On BLE ..."
            }

            local m = create_main_menu(wait_menu)
            m:show()

            local r_state, pwr_state = lnondsp.ble_get_power_state()
            if not r_state then
                slog:win("ble_init ble_get_power_state fail, return "..tostring(pwr_state))
                return false
            end

            if pwr_state == 1 then
                wait_menu.tips  = "BLE init: Power ON Success"
                wait_menu[1] = "BLE init Power ON Success"
                m:show()

                return true
            end

            local r_en, r_errno = lnondsp.ble_set_power_state(1)
            if not r_en then
                slog:win("ble_init set power on fail, return "..tostring(r_errno))
                return false
            end

            local r_state, pwr_state = lnondsp.ble_get_power_state()
            if not r_state then
                slog:win("ble_init ble_get_power_state fail, return "..tostring(pwr_state))
                return false
            end

            if pwr_state == 0 then
                slog:win("ble_init ble_set_power_state fail, state : "..tostring(pwr_state))
                return false
            end

            wait_menu.tips  = "BLE init: Power ON Success"
            wait_menu[1] = "BLE init Power ON Success"
            m:show()

            return true
        end,

        wait_connect = function(t, timeout)
            local wait_menu = {
                title = "BLE INIT",
                tips  = "Wait for devices connecting ...",
                multi_select_mode = false,
            }

            local connect_status = {
                [0] = "init",
                [1] = "advertising",
                [2] = "connected",
                [3] = "disconnected"
            }

            wait_menu[1] =  "connect state: "..tostring(connect_status[0])
            local m = create_main_menu(wait_menu)
            m:show()

            local tc = time_counter()
            local r_state, connect_state
            repeat
                r_state, connect_state = lnondsp.ble_get_con_state()
                if not r_state then
                    slog:win("ble_init ble_get_power_state fail, return "..tostring(connect_state))
                    return false
                end

                wait_menu[1] = "connect state: "..tostring(connect_status[connect_state])
                m:show()

                if tc() > tonumber(timeout) then
                    slog:win("ble_init ble_get_power_state timeout. No connect.")
                    return false
                end
                posix.sleep(1)
            until (2 == connect_state)

            return true
        end,

        send_start = function(t)
            local r, errno = lnondsp.ble_send_start()
            if not r then
                slog:err("ble data send: ble_send_start fail, return "..tostring(errno))
                return false
            end

            return true
        end,

        send_stop = function(t)
            local r, errno = lnondsp.ble_send_stop()
            if not r then
                slog:err("ble data send: ble_send_start fail, return "..tostring(errno))
                return false
            end

            return true
        end,

        get_send_statue = function(t)
            --[[
            local send_status = {
                [0] = "no error",
                [-1] = "data transfer error",
                [-2] = "state err,e.g.the connection is set down when datas are transfering",
                [-3] = "operation err,e.g.can not open the file"
            }
            --]]
            local r_state, send_state, errmsg = lnondsp.ble_get_send_status()
            if not r_state then
                slog:err("ble data send ble_get_send_status fail, return "..tostring(errmsg))
                return nil
            end

            return {state=send_state, msg=tostring(errmsg)}
        end,

        power_off = function(t)
            local r_state, pwr_state = lnondsp.ble_get_power_state()
            if not r_state then
                slog:win("ble_init ble_get_power_state fail, return "..tostring(pwr_state))
                return false
            end

            if pwr_state == 0 then
                return true
            end

            local r, errno = lnondsp.ble_set_power_state(0)
            if not r then
                slog:err("ble data send: ble_send_start fail, return "..tostring(errno))
                return false
            end

            return true
        end
    }
end

defunc_enable_ble = function(list_index)
    return function(t)
        if "nil" == type(t[list_index]) then
            slog:err("bt device find item nil")
            t[list_index] = "Enable BLE"
        elseif "string" == type(t[list_index]) then
            g_ble = g_ble or ble_init()
            if nil == g_ble then
                slog:win("ble init fail, please check the error msg")
                t.select_status[list_index] = false
                return false
            end

            if not g_ble:power_on() then
                slog:win("ble power on fail, please check the error msg")
                t.select_status[list_index] = false
                return false
            end

            if not g_ble:wait_connect(100) then
                slog:win("ble wait connecting fail, please check the error msg")
                t.select_status[list_index] = false
                g_ble:power_off()
                return false
            end
        end
    end
end

defunc_rx_desense_ble_send_action = {
    start = function (list_index)
        return function (t)
            if not t.select_status[list_index] then
                t.test_process_start_call = false
                return false
            end

            g_ble = g_ble or ble_init()
            if nil == g_ble then
                slog:err("ble init fail, please check the error msg")
                t.test_process_start_call = false
                return false
            end

            g_ble:send_start()
        end
    end,

    stop = function (list_index)
        return function (t)
            g_ble = g_ble or ble_init()
            if nil == g_ble then
                slog:err("ble init fail, please check the error msg")
                return false
            end

            if t.select_status[list_index] then
                g_ble:send_stop()
            end
        end
    end
}
