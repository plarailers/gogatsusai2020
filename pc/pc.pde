import processing.serial.*;

Serial myPort;  // Create object from Serial class
char val;        // Data received from the serial port

void setup() 
{
  size(200, 200);
  //Bluetoothのシリアルを選択
  myPort = new Serial(this, "/dev/cu.ESP32-ESP32SPP", 115200);//Mac
  //myPort = new Serial(this, "COM8", 115200);//Windows
}

void draw() {
  if (myPort.available() > 0) {
    val = (char)myPort.read();
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
    case 'c':
      myPort.write('c');
      println('c');
      break;
    case 'd':
      myPort.write('d');
      println('d');
      break;
  }
}
