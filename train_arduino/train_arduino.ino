/*調整する変数--------------------------------*/
int input = 130;//モーターへの初期入力(0~255)
double speed_id = 40;//車両の速度目標値(cm/s)
double kp = 1;//比例係数
double kd = 1;//微分係数
double ki = 0.001;//積分係数
/*------------------------------------------*/

const int SENSOR_PIN = 0;
const int INPUT_PIN = 6;
double speed = 0;//車両の速度
bool status = 0;
unsigned int new_time = 0;
unsigned int old_time = 0;
int period = 0;//回転周期(s)
double r = 1.0;//車輪の半径(cm)
double e0;//現在の偏差
double e1;//1つ前の偏差
double e2;//2つ前の偏差

void setup() {
  Serial.begin(9600);
  pinMode(INPUT_PIN, OUTPUT);
}

void loop(){
  
  new_time = millis();
  analogWrite(INPUT_PIN, input);
  int value = analogRead(SENSOR_PIN);
  Serial.print(value);

  //磁石がホールセンサーの上にきたら
  if (status == 0 && value >= 512) {
    status = 1;
    period = new_time - old_time;
    Serial.print(" ");
    Serial.print(period);
    old_time = new_time;
    
    //周期periodを速度speedに変換
    speed = 2000*3.1415926535*r/(double)period;
    e2 = e1;
    e1 = e0;
    e0 = speed_id - speed;
    input += (int)(kp*e0 + kd*(e0-e1) + ki*(e0+e1+e2));
    if (input > 255) {
      input = 255;
    }
    else if (input < 80) {
      input = 80;
    } 
    //ここにPCに発信する命令を書く
  }
  else if (status == 1 && value < 512) {
    status = 0;
  }
  
  Serial.print(" ");
  Serial.print(speed);
  Serial.print(" ");
  Serial.println(input);

}
  

  
