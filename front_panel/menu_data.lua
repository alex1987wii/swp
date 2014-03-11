-- menu data 

front_panel_data = {
    title = "Front Panel", 
    tips  = "Select the test item, move and space to select", 
    action = function (t)

    end, 
    select_status = {true, true, true}, 
    [1] = {
        title = "Freq", 
        tips  = "Select Freq", 
        action = function ()

        end, 
        "136.125MHz", 
        "155.125MHz", 
        "173.125MHz", 
        "Enter frequency in Hz", 
    }, 
    [2] = {
        title = "Band Width", 
        tips  = "Select Band Width", 
        action = function ()

        end, 
        "12.5 KHz", 
        "25 KHz", 
    }, 
    [3] = {
        title = "Power", 
        tips  = "Select Power", 
        action = function ()

        end, 
        "1 Watt", 
        "2 Watt", 
        "3 Watt",
    }, 
    [4] = {
        title = "Audio Path", 
        tips  = "Select Audio Path", 
        action = function ()

        end, 
        "Internal speaker / mic", 
        "External speaker / mic", 
        "BlueTooth (attempt to auto  pair)", 
    }, 
    [5] = {
        title = "Squelch", 
        tips  = "Select Squelch", 
        action = function ()

        end, 
        "none", 
        "normal", 
        "tight", 
    }, 
    [6] = {
        title = "Modulation", 
        tips  = "Select Modulation", 
        action = function ()

        end, 
        [1] = "none", 
        [2] = {
            title = "Analog", 
            tips  = "Select Analog", 
            action = function ()

            end, 
            "CTCSS (Tone = 250.3 Hz)", 
            "CDCSS (Code = 532)", 
            "MDC1200", 
            "none", 
        }, 
        [3] = {
            title = "Digital", 
            tips  = "Select Digital", 
            action = function ()

            end, 
            "DVOA", 
            "TDMA Voice", 
            "TDMA Data", 
            "ARDS Voice", 
            "ARDS Data", 
            "P25 Voice", 
            "P25 Data", 
        }, 
    },  
    [7] = {
        title = "Enable Bluetooth", 
        tips  = "Setting up bluetooth device", 
        action = function ()
            
        end, 
    }, 
    [8] = "Enable GPS", 
    [9] = "Enable LCD", 
    [10]= "Display static image(LCD)", 
    [11]= "Enable slide show", 
    [12]= "Enable LED test", 
    [13]= "Active Clone cable", 
}

table_info = function(t)
    local num = table.getn(t)
    local gp = {}
    for k, v in ipairs(t) do
        if type(v) == "string" then
            gp[k] = v
        elseif type(v) == "table" then
            if type(v.title) == "string" then
                gp[k] = v.title
            else
                lua_log.e("table_info", t.title.." "..k..".title type:"..type(v.title))
                gp[k] = "unknown item["..k.."]"
            end
        else
            lua_log.e("table_info", t.title.." "..k.." type:"..type(v))
            gp[k] = "unknown item["..k.."]"
        end
    end

    return {lists = gp, num = num}
end
