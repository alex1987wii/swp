
require "menu_show"
require "lnondsp"
require "nondsp_event_info"
require "utility"
require "log"

--slog.win_note_en = true

gsm_init = function()
    
    local wait_menu = {
        title = "GSM Initial/Register", 
        tips  = "Enable ..., plaease wait", 
        multi_select_mode = false, 
        [1] = "Enable GSM ..."
    }
    
    create_main_menu(wait_menu):show()
    
    if not global_gsm_enable then
        local r_en, r_enno = lnondsp.gsm_enable()
        if not r_en then
            slog:win("gsm_enable fail, return "..tostring(r_enno))
            return nil
        end
        posix.sleep(2)
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
                posix.sleep(2)
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
            wait_menu.tips  = "set_band ..."
            wait_menu[1] = "please wait ..."
            create_main_menu(wait_menu):show()
            local r, s = lnondsp.gsm_set_band(b)
            if not r then
                slog:err("gsm set band error: return code "..tostring(s))
            end
            posix.sleep(2)
            
            return r
        end, 
        
        get_CSQ = function ()
            return lnondsp.gsm_get_CSQ()
        end, 
        
        get_register_status = function ()
            return lnondsp.gsm_get_register_status()
        end, 
        
        keep_sending_gprs_datas_start = function()
            return lnondsp.gsm_keep_sending_gprs_datas_start()
        end, 
        
        keep_sending_gprs_datas_stop = function()
            return lnondsp.gsm_keep_sending_gprs_datas_stop()
        end, 
        
        disable = function(t)
            lnondsp.gsm_disable()
            global_gsm_enable = false
        end
    }
end

defunc_gsm_init_register_test = function(list_index)
    return function(t)
        if t.select_status[list_index] then
            local gsm = gsm or gsm_init()
            
            local csq = gsm.get_CSQ()
            
            local mt = {
                title = "GSM Initial/Register", 
                tips = "Register Initial Status", 
                [1] = "Register Status : ", 
                [2] = tostring(gsm.get_register_status().msg),
                [3] = "CSQ : ", 
                [4] = tostring(csq.code).." : "..tostring(csq.msg),
                update = function (self)
                    csq = gsm.get_CSQ()
                    self[1] = "Register Status : "
                    self[2] = tostring(gsm.get_register_status().msg)
                    self[3] = "CSQ : "
                    self[4] = tostring(csq.code).." : "..tostring(csq.msg)
                end, 
            }
            create_main_menu(mt):show()
            
            local ch = list_win:getch()
            
            while ch ~= key_map.stop do
                mt:update()
                create_main_menu(mt):show()
                ch = list_win:getch()
            end
        end
    end
end

def_gsm_enable = function(list_index)

end

