#include <BluetoothSerial.h>
BluetoothSerial SerialBT;

/*調整する変数--------------------------------*/
int input = 50;//モーターへの初期入力(0~255)
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

//停止中
void stop() {
  ledcWrite(0,0);
}

void start() {
  ledcWrite(0,200);
  delay(300);
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
  SerialBT.begin("ESP32");
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

  if (SerialBT.available()>0) {
    v = SerialBT.read();
    if (v == 'a') {
      status = 1;
    }
    else if (v == '0') {
      status = 0;
      input = 0;
    }
    else if (v == '1') {
      status = 1;
      input = 10;
    }
    else if (v == '2') {
      status = 1;
      input = 20;
    }
    else if (v == '3') {
      status = 1;
      input = 30;
    }
    else if (v == '4') {
      status = 1;
      input = 40;
    }
    else if (v == '5') {
      status = 1;
      input = 50;
    }
    else if (v == '6') {
      status = 1;
      input = 60;
    }
    else if (v == '7') {
      status = 1;
      input = 70;
    }
    else if (v == '8') {
      status = 1;
      input = 80;
    }
    else if (v == '9') {
      status = 1;
      input = 90;
    }
  }

  if (status == 1) {
    ledcWrite(0, input);
//    if (new_time - old_time > 500) {
//      input += 5;
//      if (input > 255) {
//        input = 255;
//      }
//      old_time = new_time;
//      SerialBT.println(input);
//    }

    //PCに1回転ごとに信号を送る
    value = digitalRead(SENSOR_PIN);
    if (hole == 0 && value == 1) {
      hole = 1;
      SerialBT.println('o');
    } else if (hole == 1 && value == 0) {
      hole = 0;
    }
  }
  
  else if (status == 0) {
    stop();
    input = 50;
  }
}
