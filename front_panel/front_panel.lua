#!/usr/bin/lua

--[[
front panel main
--]]
require "curses"
require "posix"
require "log"

lua_log = lua_log or newlog("front_panel")

require "menu_data"
require "menu_show"

sleep = function (t) os.execute("sleep "..t) end

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
local m = create_main_menu(front_panel_data.RFT)
m:show()
m:action()

--show_menu(front_panel_data)
--menu_action(front_panel_data)

--sleep(5)

curses.endwin() 
