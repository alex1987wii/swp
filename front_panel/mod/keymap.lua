
ERR = {
    [-11] = "Try again",
    [-14] = "Bad address",
    [-19] = "No such device",
    [-22] = "Invalid argument",
}

TYPE = {
    EV_KEY = 0x01,
    EV_MSC = 0x04,
    EV_SW  = 0x05,
}

key_value = {
    [0] = "Release",
    [1] = "Press",
    [2] = "N/A",
}

key_code = {
    CH1  = {type=TYPE.EV_KEY, code=0x01, func="CH1"},
    CH2  = {type=TYPE.EV_KEY, code=0x02, func="CH2"},
    CH3  = {type=TYPE.EV_KEY, code=0x03, func="CH3"},
    CH4  = {type=TYPE.EV_KEY, code=0x04, func="CH4"},
    CH5  = {type=TYPE.EV_KEY, code=0x05, func="CH5"},
    CH6  = {type=TYPE.EV_KEY, code=0x06, func="CH6"},
    CH7  = {type=TYPE.EV_KEY, code=0x07, func="CH7"},
    CH8  = {type=TYPE.EV_KEY, code=0x08, func="CH8"},
    CH9  = {type=TYPE.EV_KEY, code=0x09, func="CH9"},
    CH10 = {type=TYPE.EV_KEY, code=0x0A, func="CH10"},
    CH11 = {type=TYPE.EV_KEY, code=0x0B, func="CH11"},
    CH12 = {type=TYPE.EV_KEY, code=0x0C, func="CH12"},
    CH13 = {type=TYPE.EV_KEY, code=0x0D, func="CH13"},
    CH14 = {type=TYPE.EV_KEY, code=0x0E, func="CH14"},
    CH15 = {type=TYPE.EV_KEY, code=0x0F, func="CH15"},
    CH16 = {type=TYPE.EV_KEY, code=0x10, func="CH16"},
    UP     = {type=TYPE.EV_KEY, code=0x11, func="UP"},
    DOWN  = {type=TYPE.EV_KEY, code=0x12, func="DOWN"},
    LEFT  = {type=TYPE.EV_KEY, code=0x13, func="LEFT"},
    RIGHT = {type=TYPE.EV_KEY, code=0x14, func="RIGHT"},
    ENTER = {type=TYPE.EV_KEY, code=0x15, func="ENTER"},
    BACK = {type=TYPE.EV_KEY, code=0x16, func="BACK"},
    ["0"] = {type=TYPE.EV_KEY, code=0x17, func="0"},
    ["1"] = {type=TYPE.EV_KEY, code=0x18, func="1"},
    ["2"] = {type=TYPE.EV_KEY, code=0x19, func="2"},
    ["3"] = {type=TYPE.EV_KEY, code=0x1A, func="3"},
    ["4"] = {type=TYPE.EV_KEY, code=0x1B, func="4"},
    ["5"] = {type=TYPE.EV_KEY, code=0x1C, func="5"},
    ["6"] = {type=TYPE.EV_KEY, code=0x1D, func="6"},
    ["7"] = {type=TYPE.EV_KEY, code=0x1E, func="7"},
    ["8"] = {type=TYPE.EV_KEY, code=0x1F, func="8"},
    ["9"] = {type=TYPE.EV_KEY, code=0x20, func="9"},
    ["*"] = {type=TYPE.EV_KEY, code=0x21, func="*"},
    ["#"] = {type=TYPE.EV_KEY, code=0x22, func="#"},
    F13 = {type=TYPE.EV_KEY, code=0x23, func="Soft Key#1"},
    F14 = {type=TYPE.EV_KEY, code=0x24, func="Soft Key#2"},
    F15 = {type=TYPE.EV_KEY, code=0x25, func="Soft Key#3"},
    F16 = {type=TYPE.EV_KEY, code=0x26, func="Soft Key#4"},
    F17 = {type=TYPE.EV_KEY, code=0x27, func="Power Key"},
    F18 = {type=TYPE.EV_KEY, code=0x28, func="Emergency Key"},
    F19 = {type=TYPE.EV_KEY, code=0x29, func="PTT Key"},
    F20 = {type=TYPE.EV_KEY, code=0x2A, func="EPTT Key"},
    F21 = {type=TYPE.EV_KEY, code=0x2B, func="Keypad Lock Key"},
    F22 = {type=TYPE.EV_KEY, code=0x2C, func="Function Status On/Off Key"},
    F23 = {type=TYPE.EV_KEY, code=0x2D, func="IM Switch Key Shift Key）"},
    F24 = {type=TYPE.EV_KEY, code=0x2E, func="Band Select Key"},
    F25 = {type=TYPE.EV_KEY, code=0x2F, func="Home Key"},
    F26 = {type=TYPE.EV_KEY, code=0x30, func="Menu Key"},
    F27 = {type=TYPE.EV_KEY, code=0x31, func="REC Key"},
    F28 = {type=TYPE.EV_KEY, code=0x32, func="Pause Key"},
    F29 = {type=TYPE.EV_KEY, code=0x33, func="REC END / Capture"},
    F30 = {type=TYPE.EV_KEY, code=0x34, func="Kill Radio Key"},
    F31 = {type=TYPE.EV_KEY, code=0x35, func="Channel up"},
    F32 = {type=TYPE.EV_KEY, code=0x36, func="Channel down"},
    F33 = {type=TYPE.EV_KEY, code=0x37, func="Play key"},
    F34 = {type=TYPE.EV_KEY, code=0x38, func="Reset key"},
    F35 = {type=TYPE.EV_KEY, code=0x39, func="Voice Message Box Key"},
    F36 = {type=TYPE.EV_KEY, code=0x40, func="Scan Key"},

    BAT_INSERT      = {type=TYPE.EV_KEY, code=0xA0, func="Insert charger"},
    BAT_PULL_OUT    = {type=TYPE.EV_KEY, code=0xA1, func="Pull out charger"},
    BAT_FULL        = {type=TYPE.EV_KEY, code=0xA2, func="Full of charger"},
    BAT_ERR         = {type=TYPE.EV_KEY, code=0xA3, func="Battery Error"},

    key_name = function(self, code)
        for k, v in pairs(self) do
            if "table" == type(v) then
                if code == v.code then
                    return k
                end
            end
        end
    end,

    key_function = function(self, code)
        for k, v in pairs(self) do
            if "table" == type(v) then
                if code == v.code then
                    return v.func
                end
            end
        end
    end,

    get_event = function(self, name)
        for k, v in pairs(self) do
            if "table" == type(v) then
                if k == name then
                    return v
                end
            end
        end
    end,
}

