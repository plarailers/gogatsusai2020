import processing.serial.*;

Serial myPort;  // Create object from Serial class
char val;        // Data received from the serial port

void setup() 
{
  size(200, 200);
  //Bluetoothのシリアルを選択
  //myPort = new Serial(this, "/dev/cu.ESP32-ESP32SPP", 115200);//Mac
  myPort = new Serial(this, "COM5", 115200);//Windows
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
    case '1':
      myPort.write(10);
      println("10");
      break;
    case '2':
      myPort.write(20);
      println("20");
      break;
    case '3':
      myPort.write(30);
      println("30");
      break;
    case '4':
      myPort.write(40);
      println("40");
      break;
    case '5':
      myPort.write(50);
      println("50");
      break;
  }
}
