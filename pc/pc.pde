import processing.serial.*;

Serial myPort;  // Create object from Serial class
char val;        // Data received from the serial port
int v;

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
    case '0':
      v = 0;
      myPort.write(v);
      println("0");
      break;
    case '1':
      v = 10;
      myPort.write(v);
      println("10");
      break;
    case '2':
      v = 20;
      myPort.write(v);
      println("20");
      break;
    case '3':
      v = 30;
      myPort.write(v);
      println("30");
      break;
    case '4':
      v = 40;
      myPort.write(v);
      println("40");
      break;
    case '5':
      v = 50;
      myPort.write(v);
      println("50");
      break;
  }
}
