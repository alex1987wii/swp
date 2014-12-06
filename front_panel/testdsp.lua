#!/usr/bin/lua

require "ldsp"
require "posix"

ldsp.bit_launch_dsp()
ldsp.register_callbacks()
ldsp.start_dsp_service()

ldsp.start_rx_desense_scan(148012500,1,6250,6,6,10,2)
posix.sleep(100)
ldsp.stop_rx_desense_scan()
posix.sleep(50)

ldsp.tx_duty_cycle_test_start(148012500, 1, 0, 1, 1, 50, 10)
posix.sleep(100)
ldsp.tx_duty_cycle_test_stop()
posix.sleep(60)

ldsp.tx_duty_cycle_test_start(148012500, 1, 0, 1, 2, 50, 10)
posix.sleep(100)
ldsp.tx_duty_cycle_test_stop()
posix.sleep(60)

ldsp.tx_duty_cycle_test_start(148012500, 1, 0, 1, 3, 50, 10)
posix.sleep(100)
ldsp.tx_duty_cycle_test_stop()
posix.sleep(60)

ldsp.tx_duty_cycle_test_start(148012500, 1, 0, 1, 4, 50, 10)
posix.sleep(100)
ldsp.tx_duty_cycle_test_stop()
posix.sleep(60)

ldsp.tx_duty_cycle_test_start(148012500, 1, 0, 1, 5, 50, 10)
posix.sleep(100)
ldsp.tx_duty_cycle_test_stop()
posix.sleep(60)

ldsp.tx_duty_cycle_test_start(148012500, 1, 0, 1, 8, 50, 10)
posix.sleep(100)
ldsp.tx_duty_cycle_test_stop()
posix.sleep(60)

ldsp.two_way_transmit_start(148012500,1,1,2,6250,10,2,2)
posix.sleep(100)
ldsp.two_way_transmit_stop()
