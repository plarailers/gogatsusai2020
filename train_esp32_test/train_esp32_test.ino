#include <BluetoothSerial.h>
BluetoothSerial SerialBT;

/*調整する変数--------------------------------*/
int input = 40;//モーターへの初期入力(0~255)
int input_max = 255;
int input_min = 25;
double speed_id = 50;//車両の速度目標値(cm/s)
double speed_max = 100;
double speed_min = 5;
double kp = 0.7;//比例係数
double kd = 1;//微分係数
double ki = 0.01;//積分係数
/*------------------------------------------*/

char v;
const int SENSOR_PIN = 4;//ホールセンサーのピンGPIO4
const int INPUT_PIN = A18;//モーターのピンGPIO25
double speed;//車両の速度
int value = 0;//ホールセンサーの値
bool hole = 0;//ホールセンサーの値valueを0or1に変換
bool status = 0;//車両の状態。1:進行、0:停止
unsigned int new_time = 0;
unsigned int old_time = 0;
int period = 0;//回転周期(s)
double r = 1.25;//車輪の半径(cm)
double e0;//現在の偏差
double e1;//1つ前の偏差
double e2;//2つ前の偏差

/*-------------------------------------------*/
//進行中に繰り返す
void move(double *speed_id) {
  ledcWrite(0, input);
  value = analogRead(SENSOR_PIN);

  Serial.print(value);
  Serial.print(" ");
  Serial.print(hole);
  Serial.print(" ");
  Serial.print(status);
  Serial.print(" ");
  Serial.print(speed);
  Serial.print(" ");
  Serial.println(input);

  

  //磁石がホールセンサーの上にきたら
  if (hole == 0 && value >= 2048) {
    hole = 1;
    period = new_time - old_time;
    old_time = new_time;
    //PCに1回転ごとに信号を送る
    SerialBT.println('o');

    //周期periodを速度speedに変換
    speed = 2000*3.1415926535*r/(double)period;
    //speedの目標値との偏差を記録
    e2 = e1;//2つ前の偏差
    e1 = e0;//1つ前の偏差
    e0 = *speed_id - speed;//現在の偏差
    //inputを更新
    input += (int)(kp*e0 + kd*(e0-e1) + ki*(e0+e1+e2));
    if (input > input_max) {
      input = input_max;
    }
    else if (input < input_min) {
      input = input_min;
    }
  }
  else if (hole == 1 && value < 2048) {
    hole = 0;
  }

  
  
}

//停止中
void stop() {
  ledcWrite(0,0);
}

void start() {
  ledcWrite(0,240);
  delay(1000);
}

void accel(double *speed_id) {
  *speed_id += 5;
  if (*speed_id >= speed_max) {
    *speed_id = speed_max;
  }
}

void brake(double *speed_id) {
  *speed_id -= 5;
  if (*speed_id <= speed_min) {
    *speed_id = speed_min;
  }
}

/*---------------------------------------------*/
void setup() {
  //SerialBT.begin("ESP32");
  ledcSetup(0, 12800, 8);
  ledcAttachPin(INPUT_PIN, 0);
  //SerialBT.println("Start!");
  Serial.begin(115200);
  pinMode(4, INPUT);
}

void loop(){

  /*Serial.print(value);
  Serial.print(" ");
  Serial.print(hole);
  Serial.print(" ");
  Serial.print(status);
  Serial.print(" ");
  Serial.print(speed);
  Serial.print(" ");
  Serial.println(input);*/

  new_time = millis();

  if (Serial.available()>0) {
    v = Serial.read();
    if (v == 'a') {
      start();
      status = 1;
    }
    else if (v == 'b') {
      status = 0;
    }
    else if (v == 'c') {
      accel(&speed_id);
    }
    else if (v == 'd') {
      brake(&speed_id);
    }
  }

  if (status == 1) {
    move(&speed_id);
  }
  else if (status == 0) {
    stop();
  }
}
