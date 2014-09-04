-- nondsp event info 
require "posix"

NONDSP_EVT = {
    [1]  = "GPS", 
    [2]  = "BT", 
    [3]  = "PM", 
    [4]  = "FAN", 
    [5]  = "ETH", 
    [6]  = "WIFI", 
    [7]  = "UART", 
    [8]  = "SPI", 
    [9]  = "KEY", 
    [10] = "CAMERA", 
    [11] = "ACCESSORY", 
    [12] = "MOTIONSENSOR", 
    [13] = "ECOMPASSSENSOR", 
    [14] = "GSM", 
    GPS = {
        [1] = "EVENT_REPORT", 
        [2] = "RCD_STORAGE_DATA_OK", 
    }, 
    BT = {
        [1]  = "ENABLE_STATE",
        [2]  = "SCAN_ID",
        [3]  = "SERIAL_DATA_RECV",
        [4]  = "DATA_RECV",
        [5]  = "DATA_SEND",
        [6]  = "SETUP_SERIAL_PORT",
        [7]  = "ESTABLISH_SCO",
        [8]  = "PING",
        [9]  = "RSSI",
        [10] = "SCAN_ID_NAME", 
    },
    --[[
    PM = {
        "", 
    },
    FAN = {
        "", 
    },
    ETH = {
        "", 
    },
    WIFI = {
        "", 
    },
    --]]
    UART = {
        [1] = "DATA_TRANS_STATE", 
    },
    SPI = {
        [1] = "DATA_TRANS_STATE", 
    },
    KEY = {
        [1] = "EVENT_REPORT", 
    },
    CAMERA = {
        [1] = "CAPTURE_STATE", 
    },
    ACCESSORY = {
        [1] = "STATE", 
    },
    MOTIONSENSOR = {
        [1] = "STATE", 
    },
    ECOMPASSSENSOR = {
        [1] = "CALIBRATION_REPORT", 
    },
    GSM = {
        [1] = "GET_DATA", 
    },
    
    get_type = function(self, t)
        if "number" == type(t) then
            return self[t]
        elseif "string" == type(t) then
            for i=1, table.getn(self) do
                if self[i] == t then
                    return i
                end
            end
            posix.syslog(posix.LOG_ERR, "NONDSP_EVT get_type no such evt type "..t)
            return nil
        else
            posix.syslog(posix.LOG_ERR, "NONDSP_EVT get_type arg type wrong: "..type(t))
            return nil
        end
    end, 
    
    get_id = function(self, t, id)
        local tt = self:get_type(t)
        if tt == nil then
            posix.syslog(posix.LOG_ERR, "NONDSP_EVT get_id no such evt type "..t)
            return nil, nil
        end
        if "number" == type(tt) then
            tt = self:get_type(tt)
        end
        
        if nil == self[tt] then
            posix.syslog(posix.LOG_ERR, "NONDSP_EVT "..tt.." no such evt id "..tostring(id))
            return nil, nil
        end
        
        if "number" == type(id) then
            return self[tt][id]
        elseif "string" == type(id) then
            for i=1, table.getn(self[tt]) do
                if self[tt][i] == id then
                    return tt, i
                end
            end
            posix.syslog(posix.LOG_ERR, "NONDSP_EVT get_id no such evt id "..id)
            return nil, nil
        else
            posix.syslog(posix.LOG_ERR, "NONDSP_EVT get_id evt id type wrong: "..type(id))
            return nil, nil
        end
    end
}
