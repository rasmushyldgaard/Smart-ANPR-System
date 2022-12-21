/*
 * Project IOT-SmartANPR
 * Description: Programmering af Argon til IoT projekt, 5. semester. 
 * Author: Jørgen og Rasmus
 * Date: 04/11 - 2022
 */

/* Kan hente nogle biblioteker ned med ctrl+shift+p -> Particle: Install Library
* JsonParserGeneratorRK, ThingSpeak
* https://docs.particle.io/reference/device-os/api/input-output/analogwrite-pwm/ 
* Kan nok bruge analogWrite(pin, value, frequency); eller analogWrite(pin, value); til servomotor. pinMode(pin, OUTPUT); <-- først
* Skal det være 50Hz? - 20ms bredde?
* 
*/


#include "..\lib\JsonParserGeneratorRK\src\JsonParserGeneratorRK.h"
#include <stdio.h> 
#include "ThingSpeak.h" //installeret ThingSpeak via Command Palette
#include <string.h>
//#include <ctime.h>  //Finde bibliotek til at tjekke timestamps.

//ThingSpeak Client
TCPClient client;
unsigned long myChannelNumber = 1917719;        //Thingspeak channel for Numberplate
const char * myReadAPIKey = ""; //API key to read from. MATLAB writes to channel, argon reads. 
String ThingSpeakString = "";                   //String for the numberplate that MATLAB found on image
String createdAt ="";                           //When the numberplate was posted to ThingSpeak

//Relating to webhooks.
bool accessGranted = false;                     //Flag set by handler/interrupt.
bool accessRejected = false;
String tempLPR = "";                            //String for holding licence plate from handler. 
//JsonWriter object/buffer to hold the data/json we create to put into QuestDB
JsonWriterStatic<256> jw;

const pin_t MIN_SERVO = D2; //Choose pin to control Servo motor. 
volatile int pos = 90;                //Variable to store the servo position. -instantiate to 90 which is closed!

SystemSleepConfiguration config;  //Global sleep configuration!
BleAdvertisingData data; //- Try global! So advertise (BLE) has access to data even after setup-function

SYSTEM_THREAD(ENABLED);

//function declarations.
void servo_open_inverted();
void servo_close_inverted();
void myHandler_nummerplade(const char *event, const char *data);
void myHandler_insert(const char *event, const char *data);
void createEventPayload(long int timestamp, String licenseplate, String symbol);
//Still working on:
bool CheckTime(String check);
String DecryptNP(String Vig);
void discBLE(void);

Timer timer(10000, servo_close_inverted, true); //close gate after 10 secs. Put stop timer into function. 
String convertToString(char* a); //https://www.geeksforgeeks.org/convert-character-array-to-string-in-c/

//Prøve at lave timer til BLE, som skal disconnecte efter et minut. 
Timer timerBLE(60000, discBLE, true);    //60 sekunder. - ved test 10 sek - bruges til at disconnecte BLE
bool sleeping = true; //om vi skal sætte timer eller ej. prøve med true for at sove fra starten. 

//============= SETUP =================================
// setup() runs once, when the device is first turned on.
void setup() {
  //Start thingspeak
  ThingSpeak.begin(client);

  // Put initialization like pinMode and begin functions here. 
  pinMode(MIN_SERVO, OUTPUT); //Prøve at sætte pin op til servo!
  analogWriteResolution(MIN_SERVO, 12); // sets analogWrite resolution to 12 bits

  // Subscribe to the integration response event
  Particle.subscribe("hook-response/nummerplade", myHandler_nummerplade, MY_DEVICES);
  Particle.subscribe("hook-response/insert", myHandler_insert, MY_DEVICES);

//Test BLE
  data.appendLocalName("IoT-ANPR");
  BLE.advertise(&data);

  //Low power mode setup, Sleep
  config.mode(SystemSleepMode::STOP)
        //.duration(15min)        //duration sammen med .ble() ser ud til at crashe argon. Hver for sig ikke problem.
        .network(NETWORK_INTERFACE_CELLULAR)
        .ble();

}

//============= LOOP ===================================
// loop() runs over and over again, as quickly as it can execute.
void loop() {

  if(sleeping){ // when we wake up.
    if(BLE.connected()){  //set some flags and start timer if BLE woke us. 
      delay(1000); //delay to let serial connection start up.
      timerBLE.start();
      sleeping = false;
      Serial.printf("Just woke up :)\n");
    }
  }

  if (!sleeping){ //Main business logic.
  // delay reading new value from Cloud
  delay(1000);

  // Read the latest value from field 1 of Numberplate
  ThingSpeakString = ThingSpeak.readStringField(myChannelNumber, 1, myReadAPIKey);

  //Decrypt Crypto Stream Cipher read from ThingSpeak
  String crypto = DecryptNP(ThingSpeakString);

  //Read when it was created to not use an old value!
  createdAt = ThingSpeak.readCreatedAt(myChannelNumber, myReadAPIKey);
  
  //Test if the time is newer than last and within 30 secs  
  if (CheckTime(createdAt)){
    //Check licence plate
    Particle.publish("nummerplade", crypto);     //Søge efter nummerplade
  }
  
  // Hvis test bestået åbne port, insert i questdb, vente 10 sec og lukke
  if( accessGranted ){  //if we get confirmed access
    //send data to questDB
    long timestamp = (long)Time.now();                      //https://docs.particle.io/reference/device-os/api/time/now/
    createEventPayload(timestamp, tempLPR, "Approved");
    //Lave insert webhook.
    Particle.publish("insert", jw.getBuffer(), PRIVATE);    //indsætte i QuestDB - https://docs.particle.io/reference/cloud-apis/webhooks/#event
    Serial.printf("Publish insert accepted\n");  //Debugging
    //open gate
    servo_open_inverted();
    Serial.printf("Servo open\n");
    //set openGate to false
    accessGranted = false;
    //Use timer to call close function after 10 secs. 
    timer.start();
    //timerBLE.start();//give 60 more seconds for checking.
  }

  //Insert car info into QuestDB if rejected/unknown.
  if(accessRejected){
    //send data to questDB
    long timestamp = (long)Time.now();                      //https://docs.particle.io/reference/device-os/api/time/now/
    createEventPayload(timestamp, crypto, "Denied"); //We have to use ThingSpeakString, since no LPR from search is returned.
                                                     //Skifte fra ThingSpeakString til crypto efter at vi har lavet kryptering. 
    
    //Lave insert webhook.
    Particle.publish("insert", jw.getBuffer(), PRIVATE);    //indsætte i QuestDB - https://docs.particle.io/reference/cloud-apis/webhooks/#event
    Serial.printf("Publish insert rejected\n");    //Debugging message
    accessRejected = false;

    //timerBLE.start();//give 60 more seconds for checking.
  }
  
  }//if (!sleeping)
  else{ 
    Serial.printf("Going to sleep!\n");
    delay(1000);
    System.sleep(config);
  }

} //LOOP


void servo_close_inverted(){
  Serial.printf("Inside servo_close_inverted\n"); //Debugging
for(pos; pos < 90; pos += 1)
  {                                  
  /*dutycycle er ca: 11.5 % og 1.5% for 0grader og 180grader.
  * DVS: 4095 * 0.985 for 0grader = 4034 og  4095 * 0.885 for 180grader = 3624
  * Forskel = 410
  * value = 4034 - pos*410/180;
  * Når sg90 ligger på siden og akslen er til venstre er "lige ud" midten eller "90grader" 
  */
    int value = 4034 - pos*410/180;

    analogWrite(MIN_SERVO, value, 50);        
    delay(45);                       // waits 45ms for the servo to reach the position 
  } 

  //Testing ble - close after shutting gate
    BLE.disconnect();
    sleeping = true; //sætte så timer nulstilles startes efter wakeup og vi lægger os til at sove. 
    Serial.printf("Disconnecting. In close servo\n");
    delay(3000); //delay to allow ble to disconnect.

}

void servo_open_inverted(){
  for(pos; pos>=1; pos-=1)     // goes from x degrees to 90 degrees 
  {                                
    //Se servo_close_inverted for info!
    int value = 4034 - pos*410/180;
    analogWrite(MIN_SERVO, value, 50);
    delay(45);                       // waits 45ms for the servo to reach the position 
  } 
}

void myHandler_nummerplade(const char *event, const char *data) {
  // Handle the integration response
  //Log.info("event=%s data=%s", event, (data ? data : "NULL"));  //Debugging messages
  Serial.printf("Inside myHandler_nummerplade\n");
  Serial.printf(data);
  //Instead of logging and printing. Make it so we save the numberplate. Need it to query questDB.
  char delim[2] = "~";
  int count = -1;
  char *token;
  token = strtok((char*)data, delim);
  count = atoi(token);
  if(count == 1){
    token = strtok(NULL, ",");  //skifte fra delim til "," for kun at få nummerplade sendt afsted.
    tempLPR = convertToString(token);
    accessGranted = true;
  }else if(count == 0){
    accessRejected = true;
  }
}

void myHandler_insert(const char *event, const char *data) { //this is the response to the insert into QuestDB
  // Handle the integration response
  //We do not use this for anything at the moment.
}

//Create the data we are gonna send to webhook to make insertion into QuestDB. 
void createEventPayload(long int timestamp, String licenseplate, String symbol)
{
  char ts[65];
  memset(ts, 0, sizeof ts);
  snprintf(ts, sizeof ts, "%ld000000", timestamp);
  //Add 6 zeroes because we get time in seconds and QuestDB work in microseconds.
  jw.clear();
  JsonWriterAutoObject obj(&jw);
  // Add various types of data
  jw.insertKeyValue("ts", ts);
  jw.insertKeyValue("nummerplade", licenseplate);
  jw.insertKeyValue("symbol", symbol);
}

bool CheckTime(String check){
  static String lastTime = "";
  //https://sourceware.org/newlib/libc.html
  //https://docs.particle.io/reference/device-os/api/other-functions/other-functions/
  Serial.println("Inside checktime"); //debug

  if (lastTime.equals(check)) //if last time is the same as time to check, there is no new entry.
  {
    return false;
  }

  long now = Time.now();
  
  //Convert "check" string to struct tm representation  : https://linux.die.net/man/3/strptime
  struct tm tm;
  memset(&tm, 0, sizeof(struct tm));
  strptime(check.c_str(), "%Y-%m-%dT%H:%M:%S%z", &tm);
  //use mktime to get to time_t value for easy check? https://sourceware.org/newlib/libc.html#mktime
  long timestampCheck = mktime(&tm);  
  // Set the lastTime equal to what was to be checked if successful checks. 
  if ( now-timestampCheck < 30){ //timestamp within 30 seconds of now, older is not accepted. There is some delay talking to Thingspeak  
    lastTime = check;
    return true;
  }
  
  return false;
} 

//Convert function from char array to String.
String convertToString(char* a)
{
    String s = a;
    return s;
}

//Decrypt our Vigenère Cipher
String DecryptNP(String Vig){
  char key[] = "SECURITY";
  char result[8] = {0};
  const char *ptr = Vig.c_str();
  for (int i = 0; i < 7; i++){
      result[i] = ptr[i] + 74 - key[i];
  }
  return (String(result));
} 

void discBLE(void){
  BLE.disconnect();
  sleeping = true; //sætte så timer nulstilles startes efter wakeup og argon lægger sig til at sove. 
  Serial.printf("Disconnecting. In discBLE\n");
  delay(3000); // delay for at disconnect går igennem så vi ikke "vågner" med det samme. Det er planen.
}
