import processing.serial.*;
import websockets.*;

Serial myPort;  // Create object from Serial class
char val;        // Data received from the serial port

WebsocketClient wsc;
String message = "";

void setup()
{
  size(200, 200);
  //Bluetoothのシリアルを選択
  myPort = new Serial(this, "/dev/cu.ESP32-ESP32SPP", 115200);//Mac
  //myPort = new Serial(this, "COM8", 115200);//Windows

  wsc= new WebsocketClient(this, "wss://60jt3xl73m.execute-api.ap-northeast-1.amazonaws.com/dev");
}

void draw() {
  if (myPort.available() > 0) {
    val = (char)myPort.read();
    println(val);
  }
}

void webSocketEvent(String msg){
 println(msg);
 tmp_speed = int(msg);
 myPort.write(tmp_speed);
}