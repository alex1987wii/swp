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
local load_fpl = loadfile("/userdata/Settings/set_fpl_mode.lua")
if "function" == type(load_fpl) then
    load_fpl()
end

local fpm = create_main_menu(MODE_SWITCH)
while true do
    
    while not global_fpl_mode do
        fpm:show()
        fpm:action()
    end

    local m = create_main_menu(global_fpl_mode)

    m:show()
    m:action()
    
    fpm:show()
    fpm:action()
    
    switch_self_refresh(true)
end

curses.endwin() 
