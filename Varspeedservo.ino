#include <VarSpeedServo.h>

VarSpeedServo servo1;

const int servo_pin;//サーボのピン番号を指定

void setup() {
  // put your setup code here, to run once:
  servo1.attach(servo_pin);
}

void loop() {
  servo1.write(angle,speed,true)//angle[deg]まで速度speed(1~255)で移動
  // put your main code here, to run repeatedly:
}
