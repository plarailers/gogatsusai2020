import processing.serial.*;

Serial myPort;  // Create object from Serial class
int val;        // Data received from the serial port
boolean a;

void setup() 
{
  size(200, 200);
  myPort = new Serial(this, "arduinoPort", 115200);//Bluetoothのシリアルを選択
}

void draw() {
  myPort.write('b');              
  delay(5000);
  myPort.write('a');           
  delay(5000);
}