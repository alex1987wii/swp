#/usr/bin/lua5.1

--require "posix"
require 'curses'

curses.initscr()
curses.cbreak() 
curses.echo(0)  -- not noecho !
curses.nl(0)    -- not nonl !  
local stdscr = curses.stdscr()  -- it's a userdatum
stdscr:clear()                                     
stdscr:box(0, 0)                                   
stdscr:refresh()
stdscr:mvaddstr(1,1,string.format("nw:lines() %s %d", type(curses.lines), curses.lines()))
stdscr:mvaddstr(2,1,string.format("nw:cols() %s %d", type(curses.cols), curses.cols()))  
stdscr:refresh()                                       

nw = stdscr:sub(10, 10, 5, 2)
nw:clear()
nw:box(0, 0)
nw:refresh()
nnw = stdscr:sub(8, 8, 6, 3)
--nnw:clear()
nnw:mvaddstr(0, 0, "test new window")
nnw:refresh()
                                                 
os.execute("sleep 10")
--[[
nw = curses.newwin(15, 20, 3, 1)  
nw:clear()
nw:box(0, 0)
nw:refresh()

nnw = nw:sub(12, 18, 1, 1)                      
nnw:mvaddstr(0,1,"nw:lines()", tostring(curses.lines()))
nnw:mvaddstr(2,1,"nw:cols()", tostring(curses.cols()))  
nnw:refresh()                                       
                                                 
os.execute("sleep 10")
nnw:close()
nw:close()
--]]                  
curses.endwin() 
