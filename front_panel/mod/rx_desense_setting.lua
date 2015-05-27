
--[[
path: /usr/local/share/lua/5.1/rx_desense_setting.lua

freq        /* Transmit freq, value range in UHF, VHF or WLB */
band_width  /* 0->12.5KHz, 1->25KHz */
step_size  /* 0Hz, 125000Hz, 25000Hz, 100000Hz and 1000000Hz */
step_num   /* 0~ 10000 */
msr_step_num /* 0~50 */
samples    /* 10~50000 */
delaytime   /* 0~100(seconds) */
pfm_path    /* 0 : Main Channel, High Performance Path (mixer path)  
			     1 : Main Channel, Low Performance Path (direct path)  
			     2: Auto selection (reserved for future ) */

pcm_file_path: the path of speaker' pcm file
--]]

local setting = {
    freq           = 763000000, 
    band_width    = 1, 
    step_size     = 25000, 
    step_num      = 2,
    msr_step_num = 5,
    samples       = 50,
    delaytime     = 5, 
    pfm_path     = 0, 

    pcm_file_path = "/userdata/apkr.pcm"
}

return setting
