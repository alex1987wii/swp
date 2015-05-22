
--[[
path: /usr/local/share/lua/5.1/2way_ch1_knob_setting.lua
    freq       : Hz
    band_width : 1: 12.5kHz
                 2: 25kHz
                 
    power      : 0: power profile 1
                 1: power profile 2
                 2: power profile 3
                 
    audio_path : 1: internal microphone
                 2: external microphone
                 3: bluetooth pcm input port
                 
    squelch    : 0: none
                 1: normal
                 2: tight
                 
    modulation : 1: none
                 2: CTCSS
                 3: CDCSS
                 8: MDC1200
                 12: DVOA
                 13: TDMA Voice
                 14: TDMA Data
                 15: ARDS Voice
                 16: ARDS Data
                 17: P25 Vocie
                 18: P25 Data
--]]

local setting = {
	freq = 0, 
	band_width = 1, 
	power = 1, 
	audio_path = 1, 
	squelch = 1, 
	modulation = 1, 
}

return setting
