
require "lnondsp"
require "nondsp_event_info"
--
function find_device()
    local 
    local r_en, r_enno = lnondsp.bt_enable_block(lnondsp.BT_DUT_MODE)
    if not r_en then
        posix.syslog(posix.LOG_ERR, "bt_enable_block fail, return "..tostring(r_enno))
        return nil
    end
    
    local r_scan = lnondsp.bt_scan_block()
    local evt_cnt = lnondsp.get_evt_number()                       
    local ev = lnondsp.get_evt_item(evt_cnt)
    if ev.count > 0 then
        for i=1, ev2.count do 
            print("find bt device["..i.."]: ", ev2.id[i], ev2.name[i])
        end
    else
        print("find devices: ", ev2.count)
    end
end 
--

lnondsp.register_callbacks()

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
