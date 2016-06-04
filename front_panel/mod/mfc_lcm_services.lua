-- mfc_lcm_services.lua

require "opkey"
require "utility"

require "lnondsp"

lcm = {
    [1] = "/usr/slideshow_dat_for_fcc/lcd_color_white_RGB565_320_240.dat",
    [2] = "/usr/slideshow_dat_for_fcc/lcd_color_black_RGB565_320_240.dat",
    [3] = "/usr/slideshow_dat_for_fcc/lcd_color_red_RGB565_320_240.dat",
    [4] = "/usr/slideshow_dat_for_fcc/lcd_color_green_RGB565_320_240.dat",
    [5] = "/usr/slideshow_dat_for_fcc/lcd_color_blue_RGB565_320_240.dat",
    [6] = "/usr/slideshow_dat_for_fcc/H_black_white.dat",
    [7] = "/usr/slideshow_dat_for_fcc/V_black_white.dat",
    index = 1,
    left_active = function(self)
        if self.index == 1 then
            self.index = 7
        else
            self.index = self.index - 1
        end
    end,

    right_active = function(self)
        if self.index == 7 then
            self.index = 1
        else
            self.index = self.index + 1
        end
    end,

    show = function(self)
        switch_self_refresh(false)
        local r, msgid = lnondsp.lcd_display_static_image(self[self.index], 320, 240)
    end
}

wait_and_check_lcm_show = function(t)
    local dev = "/dev/input/event0"
    local k = openkey(dev, "nonblock")
    if k == nil then
        slog:err("Err: open "..dev)
        return false
    end

    lcm:show()

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
                if v.code == 0x23 and 0 == v.value then
                    lcm:left_active()
                    lcm:show()
                elseif v.code == 0x26 and 0 == v.value then
                    lcm:right_active()
                    lcm:show()
                end
            end
        end

        posix.sleep(1)
    end
end

wait_and_check_lcm_show()
