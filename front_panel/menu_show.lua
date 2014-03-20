-- menu show 

init_menu = function()
    local lines = curses.lines()
    local cols  = curses.cols()
    
    stdscr:clear()
    stdscr:box(0, 0)
    for i=1, cols-2 do
        stdscr:mvaddstr(2, i, "-")
        stdscr:mvaddstr(lines-4, i, "-")
    end
    stdscr:refresh()
    
    title_win = stdscr:sub(1, cols-2, 1, 1)
    if nil == title_win then
        return {ret = false, errmsg = "stdscr:sub title_win create fail"}
    end
    title_win:clear()
    
    tips_win = stdscr:sub(2, cols-2, lines-3, 1)
    if nil == tips_win then
        return {ret = false, errmsg = "stdscr:sub tips_win create fail"}
    end
    tips_win:clear()
    
    list_win = stdscr:sub(lines-7, cols-2, 3, 1)
    if nil == list_win then
        return {ret = false, errmsg = "stdscr:sub list_win create fail"}
    end
    list_win:keypad()
    list_win:clear()
    
    return {ret = true}
end

get_string_in_window = function(note)
    local lines = curses.lines()
    local cols  = curses.cols()
    
    local nw = stdscr:sub(5, cols-4, 4, 3)
    if nil == nw then
        return {ret = false, errmsg = "stdscr:sub get_string_in_window create fail"}
    end
    nw:clear()
    nw:refresh()
    curses.echo(true)
    nw:box(0, 0)
    nw:mvaddstr(1, 1, note)
    nw:move(2, 1)
    nw:refresh()
    local str = nw:getstr()
    nw:close()
    curses.echo(false)
    return {ret = true, str = str}
end

note_in_window = function(note)

end

create_main_menu = function(main_menu_table)
    return {
        main_table = main_menu_table, 
        show = function(self, ...)
            local info = function(s) lua_log.i("show", s) end

            local menu_table = arg[1] or self.main_table
            title_win:clear()
            if "string" == type(menu_table.title) then
                title_win:mvaddstr(0, 0, menu_table.title)
            else 
                title_win:mvaddstr(0, 0, "no title")
            end
            title_win:refresh()

            tips_win:clear()
            if "string" == type(menu_table.tips) then
                tips_win:mvaddstr(0, 0, "Tips: "..menu_table.tips)
            else 
                tips_win:mvaddstr(0, 0, "Tips: no tips")
            end
            tips_win:refresh()

            list_win:clear()
            local gp = table_info (menu_table)

            for k, v in ipairs(gp.get_group()) do
                list_win:mvaddstr(k-1, 2, v)
                if menu_table.select_status == nil then
                    menu_table.select_status = {}
                    list_win:mvaddstr(k-1, 0, " ")
                elseif menu_table.select_status[k] == nil then
                    list_win:mvaddstr(k-1, 0, " ")
                elseif not menu_table.select_status[k] then
                    list_win:mvaddstr(k-1, 0, " ")
                else
                    list_win:mvaddstr(k-1, 0, "*")
                end
            end

            if nil == menu_table.select_index then
                menu_table.select_index = 1
            end

            list_win:move(menu_table.select_index-1, 1)

            list_win:refresh()
        end, 
        
        action = function(self, ...)
            local info = function(s) lua_log.i("action", s) end
            
            local menu_table = arg[1] or self.main_table
            while true do
                local ch = list_win:getch()
                --
                tips_win:mvaddstr(1, 0, "Tips: get ch "..tonumber(ch))
                tips_win:refresh()
                
                --
                if ch == curses.KEY_DOWN then  -- down 

                    if menu_table.select_index < table.getn(menu_table) then
                        menu_table.select_index = menu_table.select_index + 1
                    end

                elseif ch == curses.KEY_UP then  -- up 
                    if menu_table.select_index > 1 then
                        menu_table.select_index = menu_table.select_index - 1
                    end
                elseif ch == 0x20 then -- space 
                    if menu_table.select_status == nil then
                        menu_table.select_status = {}
                    end
                    
                    -- if radio select, clear other select status 
                    if not menu_table.multi_select_mode then
                        if menu_table.select_status[menu_table.select_index] == nil then
                            menu_table.select_status = {}
                        elseif menu_table.select_status[menu_table.select_index] then
                            menu_table.select_status = {}
                            menu_table.select_status[menu_table.select_index] = true
                        else
                            menu_table.select_status = {}
                            menu_table.select_status[menu_table.select_index] = false
                        end
                    end
                    
                    if menu_table.select_status[menu_table.select_index] == nil then
                        menu_table.select_status[menu_table.select_index] = true
                    elseif menu_table.select_status[menu_table.select_index] then
                        menu_table.select_status[menu_table.select_index] = false
                    else
                        menu_table.select_status[menu_table.select_index] = true
                    end

                elseif ch == 0xa then  -- ENTER 
                    if menu_table.select_status == nil then
                        menu_table.select_status = {}
                    end

                    -- if radio select, clear other select status 
                    if not menu_table.multi_select_mode then
                        menu_table.select_status = {}
                    end
                    menu_table.select_status[menu_table.select_index] = true

                    if type(menu_table[menu_table.select_index]) == "table" then
                        if "function" == type(menu_table[menu_table.select_index].new_main_menu) then
                             menu_table[menu_table.select_index]:new_main_menu()
                        else
                            self:show(menu_table[menu_table.select_index])
                            self:action(menu_table[menu_table.select_index])
                        end
                    end
                elseif ch == curses.KEY_LEFT then  -- <- left, goto pre-menu 
                    return true
                elseif ch == 0x2a then   -- * start test process 
                    if menu_table == self.main_table then
                        if "function" == tyep(self.test_process_start) then
                            self:test_process_start()
                        end
                    end
                elseif ch == 0x23 then  -- # stop test process
                    if menu_table == self.main_table then
                        if "function" == tyep(self.test_process_start) then
                            self:test_process_stop()
                            self:test_process_report()
                        end
                    end
                end
                
                self:show(menu_table)
            end
        end
    }
end
