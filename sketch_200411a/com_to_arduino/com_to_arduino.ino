//komabasai2019ブランチのarduino/stationのコードを改変して利用しています。
#include<VarSpeedServo.h>

//サーボ関係の定数、変数
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

//CdS関係の変数、定数
const int sensorPin = A6; //CdSセンサーの計測
int cds[6] =  {};//差分制御用（マーカー）　番号が大きいほど最新
double ave[4] = {};
const int df = 4;
int value;
const int train_coming = 1; //CdSからの情報で車両が来ていることがわかったらPCに送るデータ。多分適当に変えた方が良い。
const int train_not_coming = 0; //CdSからの情報で車両が来ていないことがわかったらPCに送るデータ。多分適当に変えた方が良い。


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

//CdSセンサーのデータを元に車両が来ているかいないか判定してPCにその情報を送る関数。
void CdS_process(){
  value = analogRead(sensorPin);  //CdSセンサーで明るさを計測
  //Serial.print(" light:");
  //Serial.println(value);  //読み取った明るさを表示

  for(int i=0; i<5; i++){
    cds[i] = cds[i+1];
  }

  cds[5] = value;
  ave[0] = (cds[0]+cds[1]+cds[2])/3;//移動平均を計算
  ave[1] = (cds[1]+cds[2]+cds[3])/3;
  ave[2] = (cds[2]+cds[3]+cds[4])/3;
  ave[3] = (cds[3]+cds[4]+cds[5])/3;

  if((ave[2]-ave[3]) > df && (ave[1]-ave[2]) > df && (ave[0]-ave[1]) > df){
    Serial.print("train is coming");
    Serial.write(train_coming);
  }
  else {
    Serial.print("train is not coming");
    Serial.write(train_not_coming);
  }
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
    CdS_process(); //CdSセンサーからの情報をPCに送る。
  }
}