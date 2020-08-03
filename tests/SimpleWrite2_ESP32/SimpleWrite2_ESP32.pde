import processing.serial.*;

Serial myPort;  // Create object from Serial class
int val;        // Data received from the serial port
boolean a;

void setup() 
{
  size(200, 200);
  myPort = new Serial(this, "COM8", 115200);//Bluetoothのシリアルを選択
}

void draw() {
  myPort.write('b');              
  delay(5000);
  myPort.write('c');             
  delay(5000);
  myPort.write('a');           
  delay(5000);
}

/*
  // Wiring/Arduino code:
 #include <BluetoothSerial.h>
BluetoothSerial SerialBT;
char v;
const int motorPin = A15; 

void setup() {
  SerialBT.begin("ESP32");
  ledcSetup(0,12800,8); 
  ledcAttachPin(motorPin, 0);
  SerialBT.println("Start!");
}

void loop() {
    SerialBT.println(v);
    if (SerialBT.available()>0){
      v = SerialBT.read();
      if(v == 'a') ledcWrite(0, 0);
      else if(v == 'b') ledcWrite(0, 200);
      else if(v == 'c') ledcWrite(0, 255);

    }
}
 */
