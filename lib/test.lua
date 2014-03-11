#!/usr/bin/lua5.1

require "posix"
require 'curses'

curses.initscr()
curses.cbreak() 
curses.echo(0)  -- not noecho !
curses.nl(0)    -- not nonl !  
local stdscr = curses.stdscr()  -- it's a userdatum
stdscr:clear()                                     
stdscr:box(0, 0)                                   
stdscr:refresh()

nw = stdscr:sub(15, 10, 2, 2)
nw:clear()
stdscr:box(0, 0)
for i=1, 12 do
	nw:move(i, 2)
	nw:refresh()
	os.execute("sleep 1")
end

loop_print_table = function (t, msg)
    
    stdscr:move(1, 1)
    stdscr:printw(msg)
                  
    if type(t) ~= "table" then
        stdscr:printw("is not table, type "..type(t))
        return                                       
    end                                              
    for k, v in pairs(t) do
        if type(v) == "string" then
            stdscr:printw(k.."-s> "..v)
        elseif type(v) == "number" then
            stdscr:printw(k.."-n> "..v)
        elseif type(v) == "table" then 
            loop_print_table(v, msg.."->"..k.."->")
        else                                       
            stdscr:printw(k.." type -> "..type(v))  
        end                                      
        stdscr:refresh()       
        os.execute("sleep 1")
    end                      
                             
    stdscr:printw("end of "..msg)
    stdscr:refresh()         
end                              
    
--local c = stdscr:getch()
os.execute("sleep 5")     
                          
loop_print_table(curses, "curses")
nw = curses.newwin(15, 20, 3, 1)  
nw:box(0, 0)                      
nw:mvaddstr(1, 1, string.format("nw:lines() %d", curses.lines()))
nw:mvaddstr(2, 1, string.format("nw:cols() %d", curses.cols()))  
nw:refresh()                                       
                                                 
os.execute("sleep 10")
                      
curses.endwin() 
