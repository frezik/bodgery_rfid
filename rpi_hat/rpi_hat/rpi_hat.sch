EESchema Schematic File Version 4
LIBS:rpi_hat-cache
EELAYER 26 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title ""
Date ""
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L Connector:Raspberry_Pi_2_3 J1
U 1 1 5C745CCB
P 5250 3500
F 0 "J1" H 5250 4978 50  0000 C CNN
F 1 "Raspberry_Pi_2_3" H 5250 4887 50  0000 C CNN
F 2 "Pin_Headers:Pin_Header_Straight_2x20" H 5250 3500 50  0001 C CNN
F 3 "https://www.raspberrypi.org/documentation/hardware/raspberrypi/schematics/rpi_SCH_3bplus_1p0_reduced.pdf" H 5250 3500 50  0001 C CNN
F 4 "1528-1785-ND" H 5250 3500 50  0001 C CNN "Digikey #"
	1    5250 3500
	1    0    0    -1  
$EndComp
$Comp
L Regulator_Linear:L7805 U1
U 1 1 5C745F83
P 2700 2100
F 0 "U1" H 2700 2342 50  0000 C CNN
F 1 "L7805" H 2700 2251 50  0000 C CNN
F 2 "Pin_Headers:Pin_Header_Angled_1x03" H 2725 1950 50  0001 L CIN
F 3 "" H 2700 2050 50  0001 C CNN
F 4 "1589-1465-ND" H 2700 2100 50  0001 C CNN "Digikey #"
	1    2700 2100
	1    0    0    -1  
$EndComp
$Comp
L Device:C C1
U 1 1 5C746050
P 2400 2400
F 0 "C1" H 2515 2446 50  0000 L CNN
F 1 "2.2uF" H 2515 2355 50  0000 L CNN
F 2 "Capacitors_SMD:C_0402" H 2438 2250 50  0001 C CNN
F 3 "~" H 2400 2400 50  0001 C CNN
F 4 "490-12532-1-ND" H 2400 2400 50  0001 C CNN "Digikey #"
	1    2400 2400
	1    0    0    -1  
$EndComp
$Comp
L Device:C C2
U 1 1 5C746087
P 3000 2400
F 0 "C2" H 3115 2446 50  0000 L CNN
F 1 "10uF" H 3115 2355 50  0000 L CNN
F 2 "Capacitors_SMD:C_0805" H 3038 2250 50  0001 C CNN
F 3 "~" H 3000 2400 50  0001 C CNN
F 4 "1276-6456-1-ND" H 3000 2400 50  0001 C CNN "Digikey #"
	1    3000 2400
	1    0    0    -1  
$EndComp
Wire Wire Line
	3000 2250 3000 2100
Wire Wire Line
	2400 2100 2400 2250
Wire Wire Line
	2700 2400 2700 2550
Wire Wire Line
	2700 2550 2400 2550
Wire Wire Line
	2700 2550 3000 2550
Connection ~ 2700 2550
$Comp
L power:GND #PWR0101
U 1 1 5C74612B
P 2700 2650
F 0 "#PWR0101" H 2700 2400 50  0001 C CNN
F 1 "GND" H 2705 2477 50  0000 C CNN
F 2 "" H 2700 2650 50  0001 C CNN
F 3 "" H 2700 2650 50  0001 C CNN
	1    2700 2650
	1    0    0    -1  
$EndComp
Wire Wire Line
	2700 2550 2700 2650
Text GLabel 2250 2100 0    50   Input ~ 0
Vin
Wire Wire Line
	2250 2100 2400 2100
Connection ~ 2400 2100
Text GLabel 3150 2100 2    50   Input ~ 0
Vcc
Wire Wire Line
	3150 2100 3000 2100
Connection ~ 3000 2100
Text GLabel 5050 2000 1    50   Input ~ 0
Vcc
Wire Wire Line
	5050 2000 5050 2200
$Comp
L power:GND #PWR0102
U 1 1 5C7464FA
P 5200 4900
F 0 "#PWR0102" H 5200 4650 50  0001 C CNN
F 1 "GND" H 5205 4727 50  0000 C CNN
F 2 "" H 5200 4900 50  0001 C CNN
F 3 "" H 5200 4900 50  0001 C CNN
	1    5200 4900
	1    0    0    -1  
$EndComp
Wire Wire Line
	4850 4800 4950 4800
Wire Wire Line
	4950 4800 5050 4800
Connection ~ 4950 4800
Wire Wire Line
	5050 4800 5150 4800
Connection ~ 5050 4800
Wire Wire Line
	5150 4800 5200 4800
Connection ~ 5150 4800
Wire Wire Line
	5250 4800 5350 4800
Connection ~ 5250 4800
Wire Wire Line
	5350 4800 5450 4800
Connection ~ 5350 4800
Wire Wire Line
	5450 4800 5550 4800
Connection ~ 5450 4800
Wire Wire Line
	5200 4900 5200 4800
Connection ~ 5200 4800
Wire Wire Line
	5200 4800 5250 4800
$Comp
L Connector:Screw_Terminal_01x02 J2
U 1 1 5C747072
P 2650 3150
F 0 "J2" H 2730 3142 50  0000 L CNN
F 1 "Screw_Terminal_01x02" H 2730 3051 50  0000 L CNN
F 2 "Terminal_Blocks:TerminalBlock_Pheonix_MKDS1.5-2pol" H 2650 3150 50  0001 C CNN
F 3 "~" H 2650 3150 50  0001 C CNN
F 4 "277-1667-ND" H 2650 3150 50  0001 C CNN "Digikey #"
	1    2650 3150
	1    0    0    -1  
$EndComp
Text GLabel 2350 3150 0    50   Input ~ 0
Vin
Wire Wire Line
	2450 3150 2350 3150
$Comp
L power:GND #PWR0103
U 1 1 5C7471D4
P 2450 3350
F 0 "#PWR0103" H 2450 3100 50  0001 C CNN
F 1 "GND" H 2455 3177 50  0000 C CNN
F 2 "" H 2450 3350 50  0001 C CNN
F 3 "" H 2450 3350 50  0001 C CNN
	1    2450 3350
	1    0    0    -1  
$EndComp
Wire Wire Line
	2450 3250 2450 3350
$Comp
L Transistor_FET:2N7000 Q2
U 1 1 5C747739
P 9150 3100
F 0 "Q2" H 9355 3146 50  0000 L CNN
F 1 "2N7000" H 9355 3055 50  0000 L CNN
F 2 "TO_SOT_Packages_THT:TO-220_Neutral123_Horizontal" H 9350 3025 50  0001 L CIN
F 3 "https://www.fairchildsemi.com/datasheets/2N/2N7000.pdf" H 9150 3100 50  0001 L CNN
F 4 "497-2779-5-ND" H 9150 3100 50  0001 C CNN "Digikey #"
	1    9150 3100
	1    0    0    -1  
$EndComp
Text GLabel 8800 3100 0    50   Input ~ 0
Lock
Text GLabel 4300 4200 0    50   Input ~ 0
Lock
Wire Wire Line
	4300 4200 4450 4200
Text GLabel 9250 2250 1    50   Input ~ 0
Vin
$Comp
L power:GND #PWR0104
U 1 1 5C747BD6
P 9250 3400
F 0 "#PWR0104" H 9250 3150 50  0001 C CNN
F 1 "GND" H 9255 3227 50  0000 C CNN
F 2 "" H 9250 3400 50  0001 C CNN
F 3 "" H 9250 3400 50  0001 C CNN
	1    9250 3400
	1    0    0    -1  
$EndComp
$Comp
L Connector:Screw_Terminal_01x02 J5
U 1 1 5C747DD7
P 9450 2450
F 0 "J5" H 9530 2442 50  0000 L CNN
F 1 "Screw_Terminal_01x02" H 9530 2351 50  0000 L CNN
F 2 "Terminal_Blocks:TerminalBlock_Pheonix_MKDS1.5-2pol" H 9450 2450 50  0001 C CNN
F 3 "~" H 9450 2450 50  0001 C CNN
F 4 "277-1667-ND" H 9450 2450 50  0001 C CNN "Digikey #"
	1    9450 2450
	1    0    0    -1  
$EndComp
Wire Wire Line
	9250 2250 9250 2350
Text GLabel 4300 4000 0    50   Input ~ 0
Switch
Wire Wire Line
	4300 4000 4450 4000
$Comp
L Connector:Screw_Terminal_01x02 J4
U 1 1 5C7490C9
P 7500 4150
F 0 "J4" H 7580 4142 50  0000 L CNN
F 1 "Screw_Terminal_01x02" H 7580 4051 50  0000 L CNN
F 2 "Terminal_Blocks:TerminalBlock_Pheonix_MKDS1.5-2pol" H 7500 4150 50  0001 C CNN
F 3 "~" H 7500 4150 50  0001 C CNN
F 4 "277-1667-ND" H 7500 4150 50  0001 C CNN "Digikey #"
	1    7500 4150
	1    0    0    -1  
$EndComp
Text GLabel 7200 4150 0    50   Input ~ 0
Toggle
Text GLabel 7200 4250 0    50   Input ~ 0
TogglePWR
Wire Wire Line
	7300 4150 7200 4150
Wire Wire Line
	7200 4250 7300 4250
Text GLabel 5450 2000 1    50   Input ~ 0
TogglePWR
Wire Wire Line
	5450 2200 5450 2000
Text GLabel 4300 3800 0    50   Input ~ 0
Toggle
Wire Wire Line
	4300 3800 4450 3800
$Comp
L Device:LED D2
U 1 1 5C74A07C
P 7000 2850
F 0 "D2" V 7038 2733 50  0000 R CNN
F 1 "LED" V 6947 2733 50  0000 R CNN
F 2 "LEDs:LED_0603" H 7000 2850 50  0001 C CNN
F 3 "~" H 7000 2850 50  0001 C CNN
F 4 "160-1478-1-ND" V 7000 2850 50  0001 C CNN "Digikey #"
	1    7000 2850
	0    -1   -1   0   
$EndComp
$Comp
L Device:R R4
U 1 1 5C74A0F2
P 7000 2500
F 0 "R4" H 6930 2454 50  0000 R CNN
F 1 "150Ohm" H 6930 2545 50  0000 R CNN
F 2 "Resistors_SMD:R_0603" V 6930 2500 50  0001 C CNN
F 3 "~" H 7000 2500 50  0001 C CNN
F 4 "P150DBCT-ND" H 7000 2500 50  0001 C CNN "Digikey #"
	1    7000 2500
	-1   0    0    1   
$EndComp
Wire Wire Line
	7000 2700 7000 2650
$Comp
L power:GND #PWR0105
U 1 1 5C74B314
P 7000 3100
F 0 "#PWR0105" H 7000 2850 50  0001 C CNN
F 1 "GND" H 7005 2927 50  0000 C CNN
F 2 "" H 7000 3100 50  0001 C CNN
F 3 "" H 7000 3100 50  0001 C CNN
	1    7000 3100
	1    0    0    -1  
$EndComp
Wire Wire Line
	7000 3100 7000 3000
Text GLabel 7000 2250 1    50   Input ~ 0
Lock
Wire Wire Line
	7000 2250 7000 2350
$Comp
L Device:Speaker LS1
U 1 1 5C74D102
P 2400 4500
F 0 "LS1" H 2570 4496 50  0000 L CNN
F 1 "Speaker" H 2570 4405 50  0000 L CNN
F 2 "rpi_hat:PS1240P02BT" H 2400 4300 50  0001 C CNN
F 3 "~" H 2390 4450 50  0001 C CNN
F 4 "445-2525-1-ND" H 2400 4500 50  0001 C CNN "Digikey #"
	1    2400 4500
	1    0    0    -1  
$EndComp
$Comp
L Transistor_BJT:2SC1815 Q1
U 1 1 5C74D3B6
P 1800 5150
F 0 "Q1" H 1991 5196 50  0000 L CNN
F 1 "2SC1815" H 1991 5105 50  0000 L CNN
F 2 "TO_SOT_Packages_THT:TO-92_Inline_Wide" H 2000 5075 50  0001 L CIN
F 3 "https://media.digikey.com/pdf/Data%20Sheets/Toshiba%20PDFs/2SC1815.pdf" H 1800 5150 50  0001 L CNN
F 4 "KSC1815YTACT-ND" H 1800 5150 50  0001 C CNN "Digikey #"
	1    1800 5150
	1    0    0    -1  
$EndComp
$Comp
L Device:R R3
U 1 1 5C74D46A
P 1900 4650
F 0 "R3" H 1970 4696 50  0000 L CNN
F 1 "R" H 1970 4605 50  0000 L CNN
F 2 "Resistors_SMD:R_0805" V 1830 4650 50  0001 C CNN
F 3 "~" H 1900 4650 50  0001 C CNN
F 4 "RNCP0805FTD1K00CT-ND" H 1900 4650 50  0001 C CNN "Digikey #"
	1    1900 4650
	1    0    0    -1  
$EndComp
Wire Wire Line
	1900 4500 2200 4500
Wire Wire Line
	2200 4600 2200 4800
Wire Wire Line
	2200 4800 1900 4800
Wire Wire Line
	1900 4800 1900 4950
Connection ~ 1900 4800
Text GLabel 2200 4250 1    50   Input ~ 0
Vcc
Wire Wire Line
	2200 4250 2200 4500
Connection ~ 2200 4500
$Comp
L power:GND #PWR0106
U 1 1 5C74F1DF
P 1900 5450
F 0 "#PWR0106" H 1900 5200 50  0001 C CNN
F 1 "GND" H 1905 5277 50  0000 C CNN
F 2 "" H 1900 5450 50  0001 C CNN
F 3 "" H 1900 5450 50  0001 C CNN
	1    1900 5450
	1    0    0    -1  
$EndComp
Wire Wire Line
	1900 5450 1900 5350
$Comp
L Device:R R1
U 1 1 5C74FA68
P 1350 5150
F 0 "R1" V 1143 5150 50  0000 C CNN
F 1 "R" V 1234 5150 50  0000 C CNN
F 2 "Resistors_SMD:R_0805" V 1280 5150 50  0001 C CNN
F 3 "~" H 1350 5150 50  0001 C CNN
F 4 "RNCP0805FTD1K00CT-ND" H 1350 5150 50  0001 C CNN "Digikey #"
	1    1350 5150
	0    1    1    0   
$EndComp
Wire Wire Line
	1500 5150 1600 5150
Text GLabel 1100 5150 0    50   Input ~ 0
Alert
Wire Wire Line
	1100 5150 1200 5150
Text GLabel 4300 3700 0    50   Input ~ 0
Alert
Wire Wire Line
	4300 3700 4450 3700
$Comp
L Device:LED D1
U 1 1 5C7516E3
P 1450 2750
F 0 "D1" V 1488 2633 50  0000 R CNN
F 1 "LED" V 1397 2633 50  0000 R CNN
F 2 "LEDs:LED_0603" H 1450 2750 50  0001 C CNN
F 3 "~" H 1450 2750 50  0001 C CNN
F 4 "SML-D12U1WT86CT-ND" V 1450 2750 50  0001 C CNN "Digikey #"
	1    1450 2750
	0    -1   -1   0   
$EndComp
$Comp
L Device:R R2
U 1 1 5C7516EB
P 1450 2400
F 0 "R2" H 1380 2354 50  0000 R CNN
F 1 "300Ohm" H 1380 2445 50  0000 R CNN
F 2 "Resistors_SMD:R_2512" V 1380 2400 50  0001 C CNN
F 3 "~" H 1450 2400 50  0001 C CNN
F 4 "RMCF2512JT300RCT-ND" H 1450 2400 50  0001 C CNN "Digikey #"
	1    1450 2400
	-1   0    0    1   
$EndComp
Wire Wire Line
	1450 2600 1450 2550
$Comp
L power:GND #PWR0107
U 1 1 5C7516F3
P 1450 3000
F 0 "#PWR0107" H 1450 2750 50  0001 C CNN
F 1 "GND" H 1455 2827 50  0000 C CNN
F 2 "" H 1450 3000 50  0001 C CNN
F 3 "" H 1450 3000 50  0001 C CNN
	1    1450 3000
	1    0    0    -1  
$EndComp
Wire Wire Line
	1450 3000 1450 2900
Text GLabel 1450 2150 1    50   Input ~ 0
Vcc
Wire Wire Line
	1450 2150 1450 2250
NoConn ~ 4450 3500
NoConn ~ 4450 3400
NoConn ~ 4450 3300
NoConn ~ 4450 3100
NoConn ~ 4450 3000
NoConn ~ 4450 2900
NoConn ~ 4450 2700
NoConn ~ 4450 2600
NoConn ~ 4450 3900
NoConn ~ 4450 4100
NoConn ~ 6050 4300
NoConn ~ 6050 4200
NoConn ~ 6050 4000
NoConn ~ 6050 3900
NoConn ~ 6050 3800
NoConn ~ 6050 3700
NoConn ~ 6050 3600
NoConn ~ 6050 3400
NoConn ~ 6050 3300
NoConn ~ 6050 3200
NoConn ~ 6050 3000
NoConn ~ 6050 2900
NoConn ~ 6050 2700
NoConn ~ 6050 2600
NoConn ~ 5150 2200
Wire Wire Line
	9250 2550 9250 2650
NoConn ~ 5350 2200
$Comp
L Connector:Screw_Terminal_01x02 J3
U 1 1 5C7482A2
P 8700 2500
F 0 "J3" H 8780 2492 50  0000 L CNN
F 1 "Screw_Terminal_01x02" H 8780 2401 50  0000 L CNN
F 2 "Terminal_Blocks:TerminalBlock_Pheonix_MKDS1.5-2pol" H 8700 2500 50  0001 C CNN
F 3 "~" H 8700 2500 50  0001 C CNN
F 4 "277-1667-ND" H 8700 2500 50  0001 C CNN "Digikey #"
	1    8700 2500
	-1   0    0    1   
$EndComp
Wire Wire Line
	9250 3300 9250 3400
Wire Wire Line
	8900 2500 8900 2750
Text GLabel 8850 2750 0    50   Input ~ 0
Switch
Wire Wire Line
	8850 2750 8900 2750
Text GLabel 8900 2200 1    50   Input ~ 0
Vcc
Wire Wire Line
	8900 2200 8900 2400
Wire Wire Line
	8800 3100 8900 3100
$Comp
L Device:D D3
U 1 1 5C76DE1A
P 8900 2950
F 0 "D3" V 8946 2871 50  0000 R CNN
F 1 "D" V 8855 2871 50  0000 R CNN
F 2 "Diodes_SMD:SOD-123" H 8900 2950 50  0001 C CNN
F 3 "~" H 8900 2950 50  0001 C CNN
F 4 "1N4148WTPMSCT-ND" V 8900 2950 50  0001 C CNN "Digikey #"
	1    8900 2950
	0    -1   -1   0   
$EndComp
Wire Wire Line
	8900 2800 8900 2750
Connection ~ 8900 2750
Connection ~ 8900 3100
Wire Wire Line
	8900 3100 8950 3100
$Comp
L Device:D_Schottky D4
U 1 1 5C75E921
P 9100 2500
F 0 "D4" V 9054 2579 50  0000 L CNN
F 1 "D_Schottky" V 9145 2579 50  0000 L CNN
F 2 "Diodes_SMD:SOD-123" H 9100 2500 50  0001 C CNN
F 3 "~" H 9100 2500 50  0001 C CNN
F 4 "MBR0540T3GOSCT-ND" V 9100 2500 50  0001 C CNN "Digikey #"
	1    9100 2500
	0    1    1    0   
$EndComp
Wire Wire Line
	9100 2350 9250 2350
Connection ~ 9250 2350
Wire Wire Line
	9250 2350 9250 2450
Wire Wire Line
	9100 2650 9250 2650
Connection ~ 9250 2650
Wire Wire Line
	9250 2650 9250 2900
$EndSCHEMATC
