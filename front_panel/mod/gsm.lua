
require "menu_show"
require "lnondsp"
require "nondsp_event_info"
require "utility"
require "log"

--slog.win_note_en = true

gsm_init = function()
    
    local wait_menu = {
        title = "GSM Enable", 
        tips  = "Enable devices ..., plaease wait", 
        multi_select_mode = false, 
        [1] = "Enable GSM ..."
    }
    
    create_main_menu(wait_menu):show()
    
    if not global_gsm_enable then
        local r_en, r_enno = lnondsp.gsm_enable()
        if not r_en then
            slog:err("gsm_enable fail, return "..tostring(r_enno))
            return nil
        end
    end
    
    global_gsm_enable = true
    
    return {
        enable = function(t)
            if not global_gsm_enable then
                local r_en, r_enno = lnondsp.gsm_enable()
                if not r_en then
                    slog:err("gsm_enable fail, return "..tostring(r_enno))
                    return nil
                end
                global_gsm_enable = true
            end
        end, 
        
        get_network_status = function(t, waittime)
            wait_menu.tips  = "get network status ..."
            wait_menu[1] = "..."
            create_main_menu(wait_menu):show()
            local tcnt = time_counter()
            local r_s
            repeat
                posix.sleep(1)
                r_s = lnondsp.gsm_get_network_status()
                wait_menu[1] = tostring(r_s.code).." "..tostring(r_s.msg)
                create_main_menu(wait_menu):show()
            until (r_s.ret and ((r_s.code == 1) or (r_s.code == 5))) or (tcnt() > tonumber(waittime))
            
            return r_s
        end, 
        
        set_band = function (b)
            local r, s = lnondsp.gsm_set_band(b)
            if not r then
                slog:err("gsm set band error: return code "..tostring(s))
            end
            
            return r
        end, 
        
        get_CSQ = function ()
            local r = lnondsp.gsm_get_CSQ()
        end, 
        
        gsm_get_register_status = function ()
            return lnondsp.gsm_get_register_status()
        end, 
        
        keep_sending_gprs_datas_start = function()
            lnondsp.gsm_keep_sending_gprs_datas_start()
        end, 
        
        keep_sending_gprs_datas_stop = function()
            lnondsp.gsm_keep_sending_gprs_datas_stop()
        end, 
        
        disable = function(t)
            lnondsp.gsm_disable()
            global_gsm_enable = false
        end
    }
end

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

