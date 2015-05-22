#!/bin/sh

unlock /

echo "11111111" > /usr/BIT/fpl_mode_en
echo "global_fpl_mode = BaseBand_MODE" > /userdata/Settings/set_fpl_mode.lua

switch_fpl_mode.sh

