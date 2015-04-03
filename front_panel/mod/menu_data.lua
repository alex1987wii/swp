-- menu data 

require "curses"
require "ldsp"
require "lnondsp"
require "log"
require "utility"
require "baseband_mode"
require "bluetooth_mode"
require "gps_mode"
require "fcc"
require "field"
require "gsm_mode"

local device_type = device_type or read_config_mk_file("/etc/sconfig.mk", "Project")
if "g4_bba" == tostring(device_type) then
    require "two_way_rf_mode_g4"
else
    require "two_way_rf_mode"
end

MODE_SWITCH = {
    title = "Front Panel Mode Ctl", 
    tips  = "select mode, <- to switch and * reboot to switch", 
    multi_select_mode = false, 
    action_map = {
        [1] = function (t)
            global_fpl_mode = t[1].fpl_mode
            t.fpl_mode_name = t[1].fpl_mode_name
        end, 
        [2] = function (t) 
            t.reboot_mode = "app"
        end, 
    }, 
    action = function (t)
        if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
            t.action_map[t.select_index](t)
        end
    end, 
    
    [1] = {
        title = "select to fpl Mode", 
        tips  = "select and reboot", 
        multi_select_mode = false, 
        action_map = {
            [1] = function (t)
                t.fpl_mode = RFT_MODE
                t.fpl_mode_name = "RFT_MODE"
            end, 
            [2] = function (t)
                t.fpl_mode = Bluetooth_MODE
                t.fpl_mode_name = "Bluetooth_MODE"
            end, 
            [3] = function (t)
                t.fpl_mode = BaseBand_MODE
                t.fpl_mode_name = "BaseBand_MODE"
            end,
            [4] = function (t) 
                t.fpl_mode = FCC_MODE
                t.fpl_mode_name = "FCC_MODE"
            end, 
            [5] = function (t)
                t.fpl_mode = GPS_MODE
                t.fpl_mode_name = "GPS_MODE"
            end, 
            [6] = function (t)
                t.fpl_mode = Field_MODE
                t.fpl_mode_name = "Field_MODE"
            end, 
            [7] = function (t)
                t.fpl_mode = GSM_MODE
                t.fpl_mode_name = "GSM_MODE"
            end, 
        }, 
        action = function (t)
            if ((t.select_index ~= nil) and ("function" == type(t.action_map[t.select_index]))) then
                t.action_map[t.select_index](t)
            end
        end, 
        
        [1] = "2Way RF Test", 
        [2] = "Bluetooth Test",
        [3] = "BaseBand Test",
        [4] = "FCC Test", 
        [5] = "GPS Test",
        [6] = "Field Test",
        [7] = "GSM Test",
    }, 
    [2] = "reboot to app Mode", 
    test_process = {
        [1] = function (t)
            if t.select_status[1] then
                if t.fpl_mode_name then
                    os.execute("echo global_fpl_mode = "..t.fpl_mode_name.." > /userdata/Settings/set_fpl_mode.lua")
                    os.execute("/usr/bin/switch_fpl_mode.sh")
                end
            else
                os.execute("rm -f /userdata/Settings/set_fpl_mode.lua")
            end
        end, 
        [2] = function (t)
            if t.select_status[2] then
                os.execute("rm -f /userdata/Settings/set_fpl_mode.lua")
                os.execute("/sbin/reboot")
            end
        end, 
    }, 
    test_process_start = function (t)
        switch_self_refresh(true)
        for i=1, table.getn(t.test_process) do
            if t.select_status[i] then
                if "function" == type(t.test_process[i]) then
                    t.test_process[i](t)
                end
            end
        end
    end, 
}

table_info = function (t)
    return {
        num = table.getn(t), 
        get_item = function (n)
            if "string" == type(n) then
                for k, v in pairs(t) do
                    if v == n then
                        return k
                    end
                    
                    if k == n then
                        return v
                    end
                end
            elseif "number" == type(n) then
                return t[n]
            else
                slog:err("table_info:get_item() type err: "..type(n))
            end
        end, 
        get_group = function ()
            local num = table.getn(t)
            local gp = {}
            for k, v in ipairs(t) do
                if type(v) == "string" then
                    gp[k] = v
                elseif type(v) == "table" then
                    if type(v.title) == "string" then
                        gp[k] = v.title
                    else
                        slog:err("table_info: "..t.title.." "..k..".title type:"..type(v.title))
                        gp[k] = "unknown item["..k.."]"
                    end
                else
                    slog:err("table_info: "..t.title.." "..k.." type:"..type(v))
                    gp[k] = "unknown item["..k.."]"
                end
            end

            return gp
        end
    }
end
