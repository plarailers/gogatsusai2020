import processing.serial.*;
import websockets.*;

Serial myPort;  // Create object from Serial class
WebsocketClient wsc;

String getTime() {
  return String.format("%02d:%02d:%02d", hour(), minute(), second());
}

void setup() {
  surface.setVisible(false);
  //Bluetoothのシリアルを選択
  //myPort = new Serial(this, "/dev/cu.ESP32-ESP32SPP", 115200);//Mac
  //myPort = new Serial(this, "/dev/cu.Bluetooth-Incoming-Port", 115200);//Macテスト用
  myPort = new Serial(this, "COM5", 115200);//Windows
  println(getTime(), "Bluetooth connected");
  wsc = new WebsocketClient(this, "wss://60jt3xl73m.execute-api.ap-northeast-1.amazonaws.com/dev");
  println(getTime(), "WebSocket connected");
}

void draw() {
  while (myPort.available() > 0) {
    int data = myPort.read();
    println(getTime(), "[Bluetooth:read]", data);
  }
}

void webSocketEvent(String msg) {
  println(getTime(), "[WebSocketEvent]", msg);
  JSONObject json_msg = parseJSONObject(msg);
  if (!json_msg.isNull("speed")) {
    int tmp_speed = json_msg.getInt("speed");
    println(getTime(), "[Bluetooth:write]", tmp_speed);
    myPort.write(tmp_speed);
  }
}
