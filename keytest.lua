#!/usr/bin/lua
-- keytest.lua

require "opkey"
require "utility"

require "lnondsp"
require "keymap"

lcm = {
    show = function(self, evt)
        print("key: ", tostring(evt.type), tostring(key_code:key_function(evt.code)), tostring(key_value[evt.value]))
    end
}

wait_and_check_lcm_show = function(t)
    local dev = "/dev/input/event0"
    local k = openkey(dev, "nonblock")
    if k == nil then
        slog:err("Err: open "..dev)
        return false
    end

    while true do

        local evts = k.readevts(70 * lkey.event_size)
        if evts.ret then
            for k, v in ipairs(evts) do
                lcm:show(v)
            end
        end

        posix.sleep(1)
    end
end

wait_and_check_lcm_show()
