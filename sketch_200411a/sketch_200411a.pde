State state;
Timetable timetable;
Display display;

void settings() {
  size(1000, 500);

}

void setup() {
  state = new State();
  timetable = new Timetable();
  display = new Display();
  display.setup();
  state.esp32.isSimulated = true;
  state.esp32.updateSimulation();
  while (state.esp32.available() > 0) {  // 各列車について行う
    int id = state.esp32.read();  // 列車id取得
    state.trainList.get(id).id = id;  // 当該列車を取得
  }
}

int prevTime = -1;
int time = 0;

void draw() {
  state.esp32.updateSimulation();
  println("time=" + time);

  // 各列車について行う
  for (Train train : state.trainList) {
    int targetSpeed = getTargetSpeed(train);
    MoveResult moveResult = state.trainList.get(train.id).move(targetSpeed/20);  // 適当な距離進ませる
    timetableUpdate(train, moveResult);  // 時刻表を更新する
  }

  // 各ポイントについて行う
  for (Junction junction : state.junctionList) {
    if (junctionControl(junction)) {  // ポイントを切り替えるべきか判定
      Junction.getById(junction.id).toggle();  // ポイントを切り替える
    }
  }

  // センサ入力で車両の位置補正を行う
  // センサ入力があったときに関数 positionAdjust(sensorId) を呼んでください
  if (keyPressed == true) {  // (デバッグ用)キーを押したらセンサ0の位置補正
    println("keyPressed");
    positionAdjust(0);
  }
  
  // 描画
  display.draw(state);
  
  try{  // 一定時間待つ
    Thread.sleep(500);   
  } catch(InterruptedException ex){
    ex.printStackTrace();
  }

  time = millis();
    
}
