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

String filename = "sample.txt";

void draw() {
  String[] lines = loadStrings(filename);
  int tmp_speed = int(lines[0]);
  myPort.write(tmp_speed);
  if (myPort.available() > 0) {
    val = (char)myPort.read();
    println(val);
  }
}