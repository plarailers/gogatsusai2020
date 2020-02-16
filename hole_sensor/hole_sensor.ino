#include <Servo.h>
const int SENSOR_PIN = 0;
const int LED_PIN = 5;

void setup() {
  Serial.begin(9600);
  pinMode( LED_PIN, OUTPUT);
}
void loop(){
  
  int value = analogRead(0);
  Serial.println(value);
  Serial.println(status);

  if (value > 500) {
    digitalWrite(LED_PIN, HIGH);
  }
  else {
    digitalWrite(LED_PIN, LOW);
  }
    
  }
  

  
