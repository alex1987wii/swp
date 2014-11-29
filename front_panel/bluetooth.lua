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

r = lnondsp.bt_enable_block(lnondsp.BT_DUT_MODE)
print("press any key to continue")                          
io.read()                                                                     
cnt = lnondsp.get_evt_number()                                                
print("evt count: "..cnt)    
print("press any key to continue")                                                      
io.read()                                                                     
ev1 = lnondsp.get_evt_item(cnt)  
print("call return "..ev1.ret)                                             
print("evt "..cnt.." "..ev1.evt.." : "..ev1.evi)   
print("press any key to continue")                                
io.read()                                                                     
r2 = lnondsp.bt_scan_block()     
print("press any key to continue")                      
io.read()                                         
cnt = lnondsp.get_evt_number()                    
print("evt count: "..cnt)       
print("press any key to continue")                       
io.read()                                         
ev2 = lnondsp.get_evt_item(cnt)    
print("call return "..ev2.ret)                 
print("evt "..(cnt).." "..ev2.evt.." : "..ev2.evi)
print("press any key to continue")     
io.read()                                         
r = lnondsp.bt_disable() 
