#!/usr/bin/lua

--[[
front panel main
--]]
require "curses"
require "posix"
require "log"
require "utility"

require "menu_show"
require "menu_data"

get_fpl_test_mode = function ()
    local ss = try_read_fpl_test_mode_setting("/usr/BIT/fpl_mode_en")
    local en = {}
    for i=1, string.len(ss) do
        if '1' == string.sub(ss, i, i) then
            en[i] = true
        else
            en[i] = false
        end
    end

    local enmode = {
        [1] = RFT_MODE,
        [2] = Bluetooth_MODE,
        [3] = BaseBand_MODE,
        [4] = FCC_MODE,
        [5] = GPS_MODE,
        [6] = Field_MODE,
        [7] = GSM_MODE,
        [8] = MFC_MODE,
    }

    en.is_enable = function (self, fpl_mode)
        for i=1, table.getn(enmode) do
            if enmode[i] == fpl_mode and self[i] then
                return true
            end
        end

        return false
    end

    return en
end

posix.setenv("TERMINFO", "/usr/share/terminfo", 1)
--posix.setenv("PWD", "/userdata/front_panel", 1)
os.execute("/usr/bin/unlock /")

curses.initscr()
curses.cbreak()
curses.echo(false)  -- not noecho !
curses.nl(true)    -- not nonl !

switch_self_refresh(true)
stdscr = curses.stdscr()
if nil == stdscr then
    slog:err("stdscr: curses.stdscr return nil")
    os.exit(-1)
end

--
local r = init_menu()
if not r.ret then
    slog:err("stdscr: "..r.errmsg)
    os.exit(-1)
end
--
local load_fpl = loadfile("/root/Settings/set_fpl_mode.lua")
if "function" == type(load_fpl) then
    load_fpl()
end

if not ("table" == type(global_fpl_mode)) then
    slog:win("the fpl test mode is not setting")
    curses.endwin()
    os.execute("/sbin/reboot")
    return
end


local fpl_mode_handle = get_fpl_test_mode()

if not fpl_mode_handle:is_enable(global_fpl_mode) then
    slog:win("the fpl test mode: "..tostring(global_fpl_mode.title).." is not enable")
    curses.endwin()
    os.execute("/sbin/reboot")
    return
end

--local fpm = create_main_menu(MODE_SWITCH)
local m = create_main_menu(global_fpl_mode)
while true do
    m:show()
    m:action()

    --[[
    while not global_fpl_mode do
        fpm:show()
        fpm:action()
    end

    local m = create_main_menu(global_fpl_mode)

    m:show()
    m:action()

    fpm:show()
    fpm:action()
    --]]

    switch_self_refresh(true)
end

curses.endwin()
