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

// Need to send a set string length, with leading zeros if there isn't
// enough
#define TARGET_STRING_LEN 10


WIEGAND wg;
int led = 13;


void setup()
{
    Serial.begin(9600);

    // default Wiegand Pin 2 and Pin 3 see image on README.md
    // for non UNO board, use wg.begin(pinD0, pinD1) where pinD0 and pinD1
    // are the pins connected to D0 and D1 of wiegand reader respectively.
    pinMode( led, OUTPUT );
    digitalWrite( led, HIGH );
    wg.begin( 10, 11 );

    delay( 1000 );
    digitalWrite( led, LOW );
}

void loop()
{
    if( wg.available() ) {
        digitalWrite( led, HIGH );
        String idstring = String( wg.getCode() );

        // If the length ends up being larger than the target, that's OK,
        // num_zeros will just be negative, and the for() loop won't add 
        // anything. We just end up sending the string verbatim below.
        int num_zeros = TARGET_STRING_LEN - idstring.length();
        String zero_pad = String( "" );
        for( int i = 0; i < num_zeros; i++ ) {
            zero_pad.concat( "0" );
        }

        Keyboard.print( zero_pad );
        Keyboard.println( idstring );

        digitalWrite( led, LOW );
	}
}
