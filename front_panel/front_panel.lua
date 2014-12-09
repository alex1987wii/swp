#!/usr/bin/lua

--[[
front panel main
--]]
require "curses"
require "posix"
require "log"

lua_log = lua_log or newlog("front_panel")

switch_self_refresh = function(flag)
    if "boolean" ~= type(flag) then
        posix.syslog(posix.LOG_ERR, "switch_self_refresh: flag type error")
        return false
    end
    if flag then
        os.execute("echo 1 > /sys/devices/platform/ad6900-lcd/self_refresh")
    else
        os.execute("echo 0 > /sys/devices/platform/ad6900-lcd/self_refresh")
    end
    
    return true
end

sleep = function (t) os.execute("sleep "..t) end

require "menu_data"
require "menu_show"

posix.setenv("TERMINFO", "/usr/share/terminfo", 1)
os.execute("/usr/bin/unlock /")

curses.initscr()
curses.cbreak() 
curses.echo(false)  -- not noecho !
curses.nl(true)    -- not nonl !  

stdscr = curses.stdscr()
if nil == stdscr then
    lua_log.e("stdscr", "curses.stdscr return nil")
    os.exit(-1)
end

--
local r = init_menu()
if not r.ret then
    lua_log.e("stdscr", r.errmsg)
    os.exit(-1)
end
--

local m = create_main_menu(FCC_MODE)
m:show()
while true do 
    switch_self_refresh(true)
    m:action()
end


curses.endwin() 
