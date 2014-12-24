
require "lnondsp"
require "nondsp_event_info"

note_in_window = note_in_window or print
--

bt_init = function()
    local r_en, r_enno = lnondsp.bt_enable_block(lnondsp.BT_DUT_MODE)
    if not r_en then
        posix.syslog(posix.LOG_ERR, "bt_enable_block fail, return "..tostring(r_enno))
        return nil
    end
    
    return {
        find_devices = function(t)
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
                posix.syslog(posix.LOG_ERR, "get_devices_table, can not scan devices")
                note_in_window("get_devices_table, can not scan devices")
                return nil
            end
            
            local menu_t = {
                title = "BT devices", 
                tips  = "select and keyin ENTER to connect device", 
                multi_select_mode = false, 
            }
            
            menu_t.devices_connect_status = {}
            menu_t.devices_count = t.devices.count
            menu_t.dev_id = {}
            for d=1, t.devices.count do
                menu_t[d] = t.devices[d].name
                menu_t.dev_id[d] = t.devices[d].id
                menu_t.devices_connect_status[d] = false
            end
            
            menu_t.action = function(tab)
                for i=1, tab.devices_count do 
                    if tab.devices_connect_status[i] then
                        lnondsp.bt_disconnect_sco(tab.dev_id[i])
                        tab.devices_connect_status[i] = false
                    end
                    
                    if tab.select_index ~= nil and tab.select_status[tab.select_index] then
                        lnondsp.bt_establish_sco_block(tab.dev_id[tab.select_index])
                    end
                end
            end
            
            return menu_t
        end, 

        disable = function(t)
            lnondsp.bt_disable()
        end
    }
end

