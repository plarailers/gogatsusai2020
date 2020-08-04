//komabasai2019ブランチのarduino/stationのコードを改変して利用しています。
#include<VarSpeedServo.h>

//サーボ関係の定数、変数
const int num_servo = 2;

VarSpeedServo servo[num_servo];

const int servoSpeed = 50; //1から255

const int servo_angle_straight[num_servo] = {0, 0}; //サーボを直進にする際の角度。適宜いじってください
const int servo_angle_curve[num_servo] = {130, 180}; //サーボを曲げる際の角度。適宜いじってください
const bool straight = true;
const bool curve = false;
bool servo_status[num_servo] = {straight, straight}; //各サーボの状態を格納。初期値は適宜いじってください。

byte data = 0;//受信データ格納用

void servo_change(byte servo_id) { //servoの向きを切り替える関数。
  if (servo_status[servo_id] == straight) {
    servo[servo_id].write(servo_angle_curve[servo_id], servoSpeed, true);
    servo_status[servo_id] = curve;
  }
  else {
    servo[servo_id].write(servo_angle_straight[servo_id], servoSpeed, true);
    servo_status[servo_id] = straight;
  }
}

//CdS関係の変数、定数
const int num_sensor = 1; //CdSの個数
const int sensorPin[num_sensor] = {A6}; //CdSセンサーの計測
int cds[num_sensor][6] =  {};//差分制御用（マーカー）　番号が大きいほど最新
double ave[num_sensor][4] = {};
const int df = 4;
int value;

//CdSセンサーのデータを元に車両が来ているかいないか判定してPCにその情報を送る関数。
void CdS_process(int sensor_id){
  value = analogRead(sensorPin[sensor_id]);  //CdSセンサーで明るさを計測
  //Serial.print(" light:");
  //Serial.println(value);  //読み取った明るさを表示
  for(int i=0; i<5; i++){
    cds[sensor_id][i] = cds[sensor_id][i+1];
  }

  cds[sensor_id][5] = value;
  ave[sensor_id][0] = (cds[sensor_id][0]+cds[sensor_id][1]+cds[sensor_id][2])/3;//移動平均を計算
  ave[sensor_id][1] = (cds[sensor_id][1]+cds[sensor_id][2]+cds[sensor_id][3])/3;
  ave[sensor_id][2] = (cds[sensor_id][2]+cds[sensor_id][3]+cds[sensor_id][4])/3;
  ave[sensor_id][3] = (cds[sensor_id][3]+cds[sensor_id][4]+cds[sensor_id][5])/3;

  if((ave[sensor_id][2]-ave[sensor_id][3]) > df && (ave[sensor_id][1]-ave[sensor_id][2]) > df && (ave[sensor_id][0]-ave[sensor_id][1]) > df){
    Serial.print(sensor_id);
    Serial.write((byte)sensor_id);
  }

}


void setup(){
  Serial.begin(9600);
  servo[0].attach(13); //()の中適当にいじるべきかもしれない。
  servo[1].attach(6);
}

void loop(){
  while(Serial.available() > 0){//シリアルで受け取った信号をもとにサーボを動かす
    data = Serial.read();
    servo_change(data);
    /*for (int i = 0; i < num_sensor; i++){
      CdS_process(sensorPin[i]); //CdSセンサーからの情報をPCに送る。
    }*/
  }
  for (int i = 0; i < num_sensor; i++){
    CdS_process(sensorPin[i]); //CdSセンサーからの情報をPCに送る。
  }
}