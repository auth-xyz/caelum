#! /bin/bash 

notify-send "Reboot" "starting now"
sleep 1560 # 26 minutes

notify-send "Reboot" "26 minute timer ended, rebooting in 5 seconds"
sleep 5 
reboot
