/* Marshall Scholz
 * uses a teensy to turn 26 bit rfid reader wiegand communication into a 
 * keyboard number string that is identical to
 * off the shelf usb rfid readers.
 * 
 * the led blinks when a card is read.
 * 
 * wigand is a 5v protocol, but the teensy is a 3.3v ic. 
 * you must use a logic level converter between the reader and teensy.
 * 
 * data0 = pin 10
 * data1 = pin 11
*/


// wigand library from here: https://github.com/monkeyboard/Wiegand-Protocol-Library-for-Arduino/blob/master/README.md
#include <Wiegand.h> 
//#include "Keyboard.h" // for leonardo only. select "keyboard" in usb type for teensy

WIEGAND wg;

int led = 13;

String idstring;

void setup() {
	Serial.begin(9600);  
	
	// default Wiegand Pin 2 and Pin 3 see image on README.md
	// for non UNO board, use wg.begin(pinD0, pinD1) where pinD0 and pinD1 
	// are the pins connected to D0 and D1 of wiegand reader respectively.
  pinMode(led, OUTPUT);
  digitalWrite(led, HIGH);
	//wg.begin();
  wg.begin(10, 11);

  delay(1000);
  digitalWrite(led, LOW);
  //Keyboard.println("wg test");
}

void loop() {
	if(wg.available())
	{  
	  digitalWrite(led, HIGH); 
    idstring = String(wg.getCode());
    Keyboard.print("000");
    Keyboard.println(idstring);
    //Keyboard.println(wg.getCode());
//		Serial.print("Wiegand HEX = ");
//		Serial.print(wg.getCode(),HEX);
//		Serial.print(", DECIMAL = ");
//		Serial.print(wg.getCode());
//		Serial.print(", Type W");
//		Serial.println(wg.getWiegandType());   


  //delay(50);         
  digitalWrite(led, LOW);   
	}
}
