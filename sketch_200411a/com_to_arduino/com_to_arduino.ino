//komabasai2019ブランチのarduino/stationのコードを改変して利用しています。
#include<VarSpeedServo.h>

VarSpeedServo servo1;
VarSpeedServo servo2;

const unsigned long servo1_Siganl0 = 0x2C;//サーボを動かす信号(これはおそらく赤外線通信仕様なのでいじった方が良い)
const unsigned long servo1_Siganl1 = 0xAC;
const unsigned long servo2_Siganl0 = 0xD0;
const unsigned long servo2_Siganl1 = 0x30;


const int servoSpeed = 50; //1から255
const int servo1_Angle0 = 0;//サーボ1を直進にするときの角度、0から180
const int servo1_Angle1 = 130; //状況に応じて調節。
const int servo2_Angle0 = 0;
const int servo2_Angle1 = 180;


unsigned long data = 0;//受信データ格納用


void servo1_0(){//サーボ1を直進にする関数
  servo1.write(servo1_Angle0, servoSpeed, true);
  }
void servo1_1(){
  servo1.write(servo1_Angle1, servoSpeed, true);
  }
void servo2_0(){
  servo2.write(servo2_Angle0, servoSpeed, true);
  }
void servo2_1(){
  servo2.write(servo2_Angle1, servoSpeed, true);
  }


void setup(){
  Serial.begin(9600);
  servo1.attach(13); //()の中適当にいじるべきかもしれない。
  servo2.attach(6);
}

void loop(){
  while(Serial.available() > 0){//シリアルで受け取った信号をもとにサーボを動かす
    data = Serial.read();
    if(data == servo1_Siganl0){
      servo1_0();
    }else if(data == servo1_Siganl1){
      servo1_1();
    }else if(data == servo2_Siganl0){
      servo2_0();
    }else if(data == servo2_Siganl1){
      servo2_1();
    }
  }
}