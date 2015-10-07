#!/bin/sh
LOCK_PIN=22
UNLOCK_PIN=25
LED_PIN=4

gpio -g write ${LOCK_PIN} 1
gpio -g write ${UNLOCK_PIN} 0
gpio -g write ${LED_PIN} 1
sleep 30
gpio -g write ${LOCK_PIN} 0
gpio -g write ${UNLOCK_PIN} 1
gpio -g write ${LED_PIN} 0
