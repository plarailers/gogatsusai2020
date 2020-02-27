import processing.serial.*;

Serial myPort;  // Create object from Serial class
int val;        // Data received from the serial port

void setup() 
{
  size(200, 200);
  myPort = new Serial(this, "/dev/cu.ESP32-ESP32SPP", 115200);//Bluetoothのシリアルを選択
}

void draw() {
  if (myPort.available() > 0) {
    val = myPort.read();
    println(val);
  }
}

void keyPressed() {
  switch( key ) {
    case 'a':
      myPort.write('a');
      println('a');
      break;
    case 'b':
      myPort.write('b');
      println('b');
      break;
  }
}
