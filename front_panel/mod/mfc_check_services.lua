-- mfc_check_services.lua

require "opkey"
require "utility"

match_mfc = function()
    local exec = os.execute

    slog:notice("mfc_check_services -> match_mfc")

    --
    exec("/usr/bin/unlock /")
    exec("echo 11111111 > /usr/BIT/fpl_mode_en")
    exec("echo global_fpl_mode=MFC_MODE > /root/Settings/set_fpl_mode.lua")
    exec("sync")
    exec("/usr/bin/lock /")
    posix.sleep(1)
    exec("/usr/bin/switch_fpl_mode.sh ")
    --
end

wait_and_check_mfc_mode = function(t)
    local dev = "/dev/input/event0"
    local k = openkey(dev, "nonblock")
    if k == nil then
        slog:err("Err: open "..dev)
        return false
    end

    local kevt = nil
    local tm = time_counter()

    while true do

        local evts = k.readevts(70 * lkey.event_size)
        if evts.ret then
            for k, v in ipairs(evts) do
                --note_in_window_delay("key code:value -> "..tostring(v.code)..":"..tostring(v.value), 2)

                --[[
                SF#[1:4] -> val[0x23:0x26]
                RESET -> 0x38 / 56D
                REC END / Capture -> 0x31 / 49D
                PowerKey: 0x27

                key code 33: *
                key code 34: #
                key value: 1 -> press, 0 -> release
                --]]
                if v.code == 0x31 and 0 == v.value then
                    if kevt and  kevt == 0x38  then
                        match_mfc()
                    else
                        kevt = v.code
                    end
                elseif v.code == 0x38 and 0 == v.value then
                    if kevt and  kevt == 0x31  then
                        match_mfc()
                    else
                        kevt = v.code
                    end
                else
                    kevt = nil
                end
            end
        end

        if tm() > t then
            k.close()
            os.exit(0)
        end

        posix.sleep(1)
    end
end
