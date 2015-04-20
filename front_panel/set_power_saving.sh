#!/bin/sh

echo 0 > /sys/power/resumereason
echo force > /sys/power/suspendmode
echo standby > /sys/power/state
