#!/usr/bin/lua

-- bluetooth.lua
--[[
module("bluetooth")
--]]
require "lnondsp"

--[[
function find_device()
    local 
    local ret_en, ret_enno = lnondsp.bt_enable_block(lnondsp.BT_POWER_ON_ONLY)
    if not ret_en then
        posix.syslog(posix.LOG_ERR, "bt_enable_block fail, return "..ret_enno)
        return nil
    end
end 
--]]
lnondsp.register_callbacks()

r = lnondsp.bt_enable_block(lnondsp.BT_DUT_MODE)
cnt = lnondsp.get_evt_number()                                                
print("enable bt after, evt count: "..cnt)    
ev1 = lnondsp.get_evt_item(cnt)  
print("enable bt event, return "..tostring(ev1.ret))                                             
print("evt["..cnt.."] "..ev1.evt.." : "..ev1.evi)   
r2 = lnondsp.bt_scan_block()     
cnt = lnondsp.get_evt_number()                    
print("bt scan block after, evt count: "..cnt)       
ev2 = lnondsp.get_evt_item(cnt)    
print("get event, call return "..tostring(ev2.ret))                 
print("evt["..tostring(cnt).."] "..ev2.evt.." : "..ev2.evi)
if ev2.count > 0 then
    for i=1, ev2.count do 
        print("find bt device["..i.."]: ", ev2.id[i], ev2.name[i])
    end
else
    print("find devices: ", ev2.count)
end

lnondsp.bt_disable()
