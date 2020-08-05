const byte max_Serial_servo_id[3] = {1, 3, 5}; //各子艦のサーボのidの中で最大のものを書いた配列

byte data = 0;//受信データ格納用

void to_child(byte servo_id){ //母艦から子艦へのデータの送信
  if (servo_id <= max_Serial_servo_id[0]) Serial1.write(servo_id);
  else if (servo_id <= max_Serial_servo_id[1]) Serial2.write(servo_id-max_Serial_servo_id[0]-1);
  else if (servo_id <= max_Serial_servo_id[2]) Serial3.write(servo_id-max_Serial_servo_id[1]-1);
  else Serial.print("error");
}

void to_pc(byte sensor_id, byte num){ //母艦からPCへのデータの送信
  if (num == 0) Serial.write(sensor_id);
  else Serial.write(sensor_id+max_Serial_servo_id[num-2]+1);
}


void setup(){
  Serial.begin(9600);
  Serial1.begin(9600);
  Serial2.begin(9600);
  Serial3.begin(9600);
}

void loop(){
  //シリアルで受け取った信号をもとに子艦に信号を受け流す。
  while(Serial.available() > 0){
    data = Serial.read();
    to_child(data);
  }
  //シリアル1~3で受け取った信号をもとにPCに信号を受け流す。
  //どこかのセンサーがバグった時に最低限他のセンサーからの信号が読み取れるような実装になっています。
  while(Serial1.available() > 0 || Serial2.available() > 0 || Serial3.available() > 0){
    if (Serial1.available() > 0) {
      data = Serial1.read();
      to_pc(data, 1);
    }
    if (Serial2.available() > 0) {
      data = Serial2.read();
      to_pc(data, 2);
    }
    if (Serial3.available() > 0) {
      data = Serial3.read();
      to_pc(data, 3);
    }
  }
}
