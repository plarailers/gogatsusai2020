#include <BluetoothSerial.h>
BluetoothSerial SerialBT;

/*調整する変数--------------------------------*/
int input = 150;//モーターへの初期入力(0~255)
double speed_id = 30;//車両の速度目標値(cm/s)
double kp = 3;//比例係数
double kd = 3;//微分係数
double ki = 0.01;//積分係数
/*------------------------------------------*/

char v;
const int SENSOR_PIN = A6;//ホールセンサーのピンGPIO34
const int INPUT_PIN = A15;//モーターのピンGPIO12
double speed = 0;//車両の速度
int value;//ホールセンサーの値
bool hole = 0;//ホールセンサーの値valueを0or1に変換
bool status = 0;//車両の状態。1:進行、0:停止
unsigned int new_time = 0;
unsigned int old_time = 0;
int period = 0;//回転周期(s)
double r = 1.0;//車輪の半径(cm)
double e0;//現在の偏差
double e1;//1つ前の偏差
double e2;//2つ前の偏差

//進行中に繰り返す
void move() {
  ledcWrite(0, input);
  value = analogRead(SENSOR_PIN);

  //磁石がホールセンサーの上にきたら
  if (hole = 0 && value >= 512) {
    hole = 1;
    period = new_time - old_time;
    old_time = new_time;
    //PCに1回転ごとに信号を送る
    SerialBT.println("c");
  }
  else if (hole = 1 && value < 512) {
    hole = 0;
  }

  //周期periodを速度speedに変換
  speed = 2000*3.1415926535*r/(double)period;
  //speedの目標値との偏差を記録
  e2 = e1;//2つ前の偏差
  e1 = e0;//1つ前の偏差
  e0 = speed_id - speed;//現在の偏差
  //inputを更新
  input += (int)(kp*e0 + kd*(e0-e1) + ki*(e0+e1+e2));
  if (input > 255) {
    input = 255;
  }
  else if (input < 0) {
    input = 0;
  }
}

//停止中
void stop() {
  ledcWrite(0,0);
}

/*---------------------------------------------*/
void setup() {
  SerialBT.begin("ESP32");
  ledcSetup(0, 12800, 8);
  ledcAttachPin(INPUT_PIN, 0);
  SerialBT.println("Start!");
}

void loop(){
  
  new_time = millis();

  if (SerialBT.available()>0) {
    v = SerialBT.read();
    if (v == 'a') {
      status = 1;
    }
    if (v == 'b') {
      status = 0;
    }
  }

  if (status = 1) {
    move();
  }
  else if (status = 0) {
    stop();
  }
}
