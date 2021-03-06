//これは車載用ESP32に書き込むコードです。
//初めて使う時は車輪の半径rを正確に設定してください。
//そのあとは動作の安定性のために「調整する変数」をいじってください。
//さらに改良する場合はmoveの中でモータを停止状態から動かす時に、inputを急増させてから徐々に落とすとうまくいくそうです。
//そのようなモータの初期トルクに対応するための対策はまだ考えられていません。

#include <BluetoothSerial.h>
BluetoothSerial SerialBT;

/*調整する変数--------------------------------*/
int input = 80;//モーターへの入力(0~255)
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
const int SENSOR_PIN = 4;//ホールセンサーのピン
const int INPUT_PIN = A18;//モーターのピン
double speed;//車両の速度
int value = 0;//ホールセンサーの値
int value2 =0;//観測用のホールセンサの値
bool hole = 0;//ホールセンサーの値valueを0or1に変換
bool status = 0;//車両の状態。1:進行、0:停止
unsigned int new_time = 0;//速度の偏差を取る際に使う。
unsigned int old_time = 0;//速度の偏差を取る際に使う。
int period = 0;//回転周期(s)
double r = 1.25;//車輪の半径(cm)
double e0;//現在の偏差
double e1;//1つ前の偏差
double e2;//2つ前の偏差

/*-------------------------------------------*/
//進行中(status==1)に繰り返す
void move(double *speed_id) {//引数のspeed_idは速度目標値
  ledcWrite(0, input);//モータにinputの入力のpwm入力を行う。
  value = digitalRead(SENSOR_PIN);//ホールセンサの値を読む。磁石の上にあると1になる。

  //磁石がホールセンサーの上にきたら
  if (hole == 0 && value == 1) {
    hole = 1;//value==1をhole==1と言い換えている。(必要ない??)
    period = new_time - old_time;//一回転の周期を計測
    old_time = new_time;
    //PCに1回転ごとに信号を送る
    SerialBT.println('o');

    //周期periodを速度speedに変換
    speed = 2000*3.1415926535*r/(double)period;
    //speedの目標値との偏差を記録
    e2 = e1;//2つ前の偏差
    e1 = e0;//1つ前の偏差
    e0 = *speed_id - speed;//現在の偏差
    //3種類の偏差を利用してinputを更新
    input += (int)(kp*e0 + kd*(e0-e1) + ki*(e0+e1+e2));
    if (input > input_max) {//inputの上限はimput_max
      input = input_max;
    }
    else if (input < input_min) {//inputの下限はinput_min
      input = input_min;
    }
  }
  //磁石がホールセンサから離れたら
  else if (hole == 1 && value==0) {
    hole = 0;
  }

  //シリアル通信の量が多いとホールセンサの読み取りが不確かになるので消している。
  /*SerialBT.print(hole);
  SerialBT.print(" ");
  SerialBT.print(*speed_id);
  SerialBT.print(" ");
  SerialBT.print(speed);
  SerialBT.print(" ");
  SerialBT.println(input);*/
  
}

//停止
void stop() {
  ledcWrite(0,0);
}

void start() {// 発車
  ledcWrite(0,240);
  delay(1000);
}


//加速
void accel(double *speed_id) {
  *speed_id += 5;//速度目標値を5上げる
  if (*speed_id >= speed_max) {//速度目標値の上限はspeed_max
    *speed_id = speed_max;
  }
}

//減速
void brake(double *speed_id) {
  *speed_id -= 5;//速度目標値を5下げる
  if (*speed_id <= speed_min) {//速度目標値の下限はspeed_min
    *speed_id = speed_min;
  }
}

/*---------------------------------------------*/
void setup() {
  SerialBT.begin("ESP32");//Bluetooth通信を開始する。
  ledcSetup(0, 12800, 8);//pwmでモータを制御する際に必要。
  ledcAttachPin(INPUT_PIN, 0);
  Serial.begin(9600);//観測用
  pinMode(4, INPUT);//ホールセンサのピン
  delay(5000);//セットアップに5秒まつ。ここは適宜変更してください。
}

void loop(){

  /*デバッグ時にセンサの読み取りを観測できる*/
  value2 = digitalRead(SENSOR_PIN);
  Serial.print(status);
  Serial.print(" ");
  Serial.print(value2);
  Serial.print(" ");
  Serial.print(speed_id);
  Serial.print(" ");
  Serial.println(input);
  
  new_time = millis();
  //SerialBT.write('a');//通信テスト用

  if (SerialBT.available()>0) {
    v = SerialBT.read();
    if (v == 'a') {//'a'を受け取ったらstatusを1にする。
      status = 1;
      start();
    }
    else if (v == 'b') {//'b'を受け取ったらstatusを0にする。
      status = 0;
    }
    else if (v == 'c') {//'c'を受け取ったら加速する(速度目標値speed_idをあげる)。
      accel(&speed_id);
    }
    else if (v == 'd') {//'d'を受け取ったら減速する(速度目標値speed_idを下げる)。
      brake(&speed_id);
    }
  }

  if (status == 1) {//'a'を受け取りstatusが1になったらmoveする。
    move(&speed_id);
  }
  else if (status == 0) {//'b'を受け取りstatusが0になったらstopする。
    stop();
  }
}
