
require "lnondsp"
require "nondsp_event_info"

note_in_window = note_in_window or function(s) posix.syslog(posix.LOG_NOTICE, "call note_in_window:"..tostring(s)) end
switch_self_refresh = switch_self_refresh or function(s) posix.syslog(posix.LOG_NOTICE, "call switch_self_refresh:"..tostring(s)) end
--

bt_init = function()
    local r_en, r_enno = lnondsp.bt_enable_block(lnondsp.BT_DUT_MODE)
    if not r_en then
        posix.syslog(posix.LOG_ERR, "bt_enable_block fail, return "..tostring(r_enno))
        return nil
    end
    
    return {
        find_devices = function(t)
            local wait_menu = {
                title = "BT devices Scan", 
                tips  = "scanning devices ..., plaease wait", 
                multi_select_mode = false, 
                [1] = "Scanning ..."
            }
            create_main_menu(wait_menu):show()
            
            local r_scan = lnondsp.bt_scan_block()
            local evt_cnt = lnondsp.get_evt_number()                       
            local ev = lnondsp.get_evt_item(evt_cnt)
            note_in_window("get evt item: evt:"..ev.evt.." evi:"..ev.evi)
            local e_id = NONDSP_EVT:get_id(ev.evt, ev.evi)
            note_in_window("e_id:"..e_id)
            if e_id ~= "SCAN_ID_NAME" then
                posix.syslog(posix.LOG_ERR, "find_devices, can not get the event SCAN_ID_NAME")
                note_in_window("find_devices, can not get the event SCAN_ID_NAME")
                return nil
            end

            if ev.count > 0 then
                t.devices = {}
                t.devices.count = ev.count
                for i=1, ev.count do 
                    t.devices[i] = {}
                    t.devices[i].id = ev.id[i]
                    t.devices[i].name = ev.name[i]
                end
                return t.devices
            else
                posix.syslog(posix.LOG_ERR, "find_devices, can not scan devices(count:"..tostring(ev.count)..")")
                note_in_window("find_devices, can not scan devices(count:"..tostring(ev.count)..")")
                return nil
            end
        end, 
        
        get_devices_table = function(t)
            if not t.devices or t.devices.count < 1 then
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
                    
                if tab.select_index ~= nil and tab.select_status[tab.select_index] then
                    lnondsp.bt_establish_sco_block(tab.dev_id[tab.select_index])
                end
            end
            
            t.menu_tab.test_process_start = function(tab)
                switch_self_refresh(true)
                g_bt = g_bt or bt_init()
                
                for i=1, tab.devices_count do 
                    if tab.devices_connect_status[i] then
                        lnondsp.bt_disconnect_sco(tab.dev_id[i])
                        tab.devices_connect_status[i] = false
                    end
                end
                
                g_bt:find_devices()
                
                tab.devices_count = t.devices.count
                tab.dev_id = {}
                for d=1, g_bt.devices.count do
                    tab[d] = g_bt.devices[d].name
                    tab.dev_id[d] = g_bt.devices[d].id
                    tab.devices_connect_status[d] = false
                end
                
            end
            
            return t.menu_tab
        end, 

        disable = function(t)
            lnondsp.bt_disable()
        end
    }
end

defunc_enable_bt = function(list_index)
    return function(t)
        if "nil" == type(t[list_index]) then
            posix.syslog(posix.LOG_ERR, "bt device find item nil")
            note_in_window("bt device find item nil")
            t[list_index] = "Find Bt Devices"
        elseif "string" == type(t[list_index]) then
            g_bt = g_bt or bt_init()

            g_bt:find_devices()
            local bt_menu = g_bt:get_devices_table()
            if nil == bt_menu then
                posix.syslog(posix.LOG_ERR, "get_devices_table, can not scan devices")
                note_in_window("get_devices_table, can not scan devices")
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
    
    g_bt:disable()
end
