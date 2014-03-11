-- menu show 

init_menu = function()
    local lines = curses.lines()
    local cols  = curses.cols()
    
    stdscr:clear()
    stdscr:box(0, 0)
    for i=1, cols-1 do
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

show_menu = function(t)
    
    title_win:clear()
    if "string" == type(t.title) then
        title_win:mvaddstr(0, 0, t.title)
    else 
        title_win:mvaddstr(0, 0, "no title")
    end
    title_win:refresh()

    tips_win:clear()
    if "string" == type(t.tips) then
        tips_win:mvaddstr(0, 0, "Tips: "..t.tips)
    else 
        tips_win:mvaddstr(0, 0, "Tips: no tips")
    end
    tips_win:refresh()


    list_win:clear()
    local gp = table_info (t)

    for k, v in ipairs(gp.lists) do
        list_win:mvaddstr(k-1, 2, v)
        if t.select_status == nil then
            t.select_status = {}
            list_win:mvaddstr(k-1, 0, " ")
        elseif t.select_status[k] == nil then
            list_win:mvaddstr(k-1, 0, " ")
        elseif not t.select_status[k] then
            list_win:mvaddstr(k-1, 0, " ")
        else
            list_win:mvaddstr(k-1, 0, "*")
        end
    end

    if nil == t.select_index then
        t.select_index = 1
    end

    list_win:move(t.select_index-1, 1)

    list_win:refresh()

    if "function" == type(t.action) then
        t:action()
    end
end

menu_action = function(t)
    while true do
        local ch = list_win:getch()
        --
        tips_win:mvaddstr(1, 0, "Tips: get ch "..tonumber(ch))
        tips_win:refresh()
        --
        if ch == curses.KEY_DOWN then  -- down 
            if t.select_index < table.getn(t) then
                t.select_index = t.select_index + 1
            end
        elseif ch == curses.KEY_UP then  -- up 
            if t.select_index > 1 then
                t.select_index = t.select_index - 1
            end
        elseif ch == 0x20 then -- space 
            if t.select_status == nil then
                t.select_status = {}
            elseif t.select_status[t.select_index] == nil then
                t.select_status[t.select_index] = true
            elseif t.select_status[t.select_index] then
                t.select_status[t.select_index] = false
            else
                t.select_status[t.select_index] = true
            end
        elseif ch == 0xa then  -- ENTER 
            if type(t[t.select_index]) == "table" then
                t.select_status[t.select_index] = true
                show_menu(t[t.select_index])
                menu_action(t[t.select_index])
            else
                show_menu(front_panel_data)
                menu_action(front_panel_data)
            end
        elseif ch == curses.KEY_LEFT then  -- <- left, goto main menu 
            show_menu(front_panel_data)
            menu_action(front_panel_data)
        elseif ch == '*' then   -- start test process 
            if t == front_panel_data then
                dotestp()
            end
        elseif ch == '#' then  -- stop test process
            if t == front_panel_data then
                killtestp()
            end
        end
        
        show_menu(t)
    end
end

dotestp = function ()
    lua_log.i("dotest", "stat test")
end

killtestp = function()
    lua_log.i("killtest", "stop test")
end
