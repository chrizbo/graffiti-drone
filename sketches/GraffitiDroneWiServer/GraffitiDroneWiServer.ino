// I stole... I mean borrowed the structure and basics from https://github.com/YuriyGorvitovskiy/ArduinoDccLibrary. Thank you!

#include <WiServer.h>
#include <EEPROM.h>
#include <NewPing.h>

extern "C" {
#include <g2100.h>
}

// Spray can solenoid configuration parameters ------------------------------
#define SPRAY_CAN_SOLENOID_PIN 3

boolean spray_can_activated = false;

// Sonar sensor configuration parameters ------------------------------
#define MAX_DISTANCE    300 // Maximum distance we want to ping for (in centimeters). Maximum sensor distance is rated at 400-500cm.
#define PING_INTERVAL   100

uint8_t current_sensor = 1; // 1 == left and 2 == right

#define LEFT_TRIGGER_PIN  7
#define LEFT_ECHO_PIN     6

unsigned long left_distance = 0;
unsigned long left_ping_timer = 0;
NewPing left_sonar(LEFT_TRIGGER_PIN, LEFT_ECHO_PIN, MAX_DISTANCE); // NewPing setup of pins and maximum distance.

#define RIGHT_TRIGGER_PIN  5
#define RIGHT_ECHO_PIN     4

unsigned long right_distance = 0;
unsigned long right_ping_timer = 0;
NewPing right_sonar(RIGHT_TRIGGER_PIN, RIGHT_ECHO_PIN, MAX_DISTANCE); // NewPing setup of pins and maximum distance.

// Wireless configuration parameters ----------------------------------------
#define SECURITY_TYPE_WEP (1)
#define SECURITY_TYPE_WPA (2)

// WiFi is using pins 9 - LED, 10,11,12,13 (SPI for WiFi communication)
unsigned char local_ip[] = {192,168,1,10};	// IP address of WiShield
unsigned char gateway_ip[] = {192,168,1,253};	// router or gateway IP address
unsigned char subnet_mask[] = {255,255,255,0};	// subnet mask for the local network

const prog_char ssid[] PROGMEM = {"MERCUSYS_C144E4"};	        // max 32 bytes
unsigned char security_type = ZG_SECURITY_TYPE_WEP;

// WPA/WPA2 passphrase
const prog_char security_passphrase[] PROGMEM = {"PASSPHRASE"};	// max 64 characters

// WEP 128-bit keys
// sample HEX keys
prog_uchar wep_keys[] PROGMEM = {	
					0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,	0x00,	// Key 0
					0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,	0x00,	// Key 1
					0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,	0x00,	// Key 2
					0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,	0x00	// Key 3
			        };

// setup the wireless mode
// infrastructure - connect to AP
// adhoc - connect to another WiFi device
unsigned char wireless_mode = WIRELESS_MODE_INFRA;

unsigned char ssid_len;
unsigned char security_passphrase_len;

// Wireless configuration parameters ----------------------------------------
void Serial_printMACAddress() {
    Serial.print("MAC Address: ");
    U8* mac = zg_get_mac();
    for (int i = 0; i< 6; ++i) {
        if (i != 0)
            Serial.print(":");
        Serial.print(mac[i], HEX);
    }    
    Serial.println();
}

void Serial_printConnectionState() {
    if(zg_get_conn_state())
        Serial.println("WiFi: Connected");
    else           
        Serial.println("WiFi: Disconnected");
}

// String to char* helper function --------------------------
char* string2char(String command){
    if(command.length()!=0){
        char *p = const_cast<char*>(command.c_str());
        return p;
    }
}

// JSON consstruction helper function ------------------------------------------
String jsonResponse() {
    return String("{ \"leftDistance\": " + String(left_distance) + ", \"rightDistance\": " + String(right_distance) + ", \"spraying\": " + (spray_can_activated ? "true" : "false") + " }");
}

// Main request handling logic -------------------------------
boolean processRequest(char* URL) {
    Serial.print(F("Request: "));
    Serial.println(URL);

    String result = "";
    String sURL(URL);

    if(sURL == "/" || sURL == "/index.json") {
        // if requesting .json then give back the current state of the sensor
        result = jsonResponse();
    } else if(sURL == "/spray/off") {
        // if requesting something like 'spray/off' turn the actuator off
        digitalWrite(SPRAY_CAN_SOLENOID_PIN, LOW);
        spray_can_activated = false;

        result = jsonResponse();
     } else if(sURL == "/spray/on") {
        // if requesting something like '/spray/on' turn the actuator on
        digitalWrite(SPRAY_CAN_SOLENOID_PIN, HIGH);
        spray_can_activated = true;

        result = jsonResponse();
    } else {
        // else give back info about the service and how to use it (aka man page)
        result = "Use /index.json to get the current state.";
    }

    Serial.print(F("Response: "));
    Serial.println(string2char(result));
    WiServer.print(string2char(result));

    return true;
}

// Distance sensor ping ready call back --------------------
void echoCheck() { // If ping received, set the sensor distance to array.
    if(current_sensor == 1 && left_sonar.check_timer()) {
        left_distance = left_sonar.ping_result / US_ROUNDTRIP_CM;
    }

    if(current_sensor == 2 && right_sonar.check_timer()) {
        right_distance = right_sonar.ping_result / US_ROUNDTRIP_CM;
    }
}

// Graffiti Drone WiServer app -----------------------------
void setup() {
    Serial.begin(9600);
    Serial.setTimeout(500); // half a second

    Serial.println(F("Initializing web server..."));
    // Initialize WiServer and have it use the sendMyPage function to serve pages
    WiServer.enableVerboseMode(true);
    WiServer.init(processRequest);    
   
    Serial_printMACAddress();
    Serial_printConnectionState();

    Serial.println(F("Initializing hardware..."));
    pinMode(SPRAY_CAN_SOLENOID_PIN, OUTPUT);
    spray_can_activated = false;

    current_sensor = 1;

    left_ping_timer = millis() + PING_INTERVAL;
    right_ping_timer = left_ping_timer + PING_INTERVAL;

    left_distance = 0;
    right_distance = 0;

    Serial.println(F("Ready"));
}

void loop() {
    // check if it is time to get the results for the left or right sonar
    if(millis() >= left_ping_timer) {               // Is it this sensor's time to ping?
        left_ping_timer += PING_INTERVAL * 2;       // Set next time this sensor will be pinged.
        left_sonar.timer_stop();                    // Make sure previous timer is canceled before starting a new ping (insurance).
        current_sensor = 1;                          // Sensor being accessed.
        left_sonar.ping_timer(echoCheck);           // Do the ping (processing continues, interrupt will call echoCheck to look for echo).
    }

    if(millis() >= right_ping_timer) {              // Is it this sensor's time to ping?
        right_ping_timer += PING_INTERVAL * 2;      // Set next time this sensor will be pinged.
        right_sonar.timer_stop();                   // Make sure previous timer is canceled before starting a new ping (insurance).
        current_sensor = 2;                          // Sensor being accessed.
        right_sonar.ping_timer(echoCheck);          // Do the ping (processing continues, interrupt will call echoCheck to look for echo).
    }

    WiServer.server_task();
    delay(10); // Don't know why but WiServer Works better.
}