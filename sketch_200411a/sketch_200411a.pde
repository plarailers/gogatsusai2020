State state;
Timetable timetable;
Display display;
Communication communication;

void settings() {
  size(1000, 500);

}

void setup() {
  state = new State();
  timetable = new Timetable();
  display = new Display();
  display.setup();
  communication = new Communication(this);
  communication.simulationMode = false;
  communication.setup();
  while (communication.availableTrainSignal() > 0) {  // 各列車について行う
    TrainSignal trainSignal = communication.receiveTrainSignal();  // 列車id取得
    int id = trainSignal.trainId;
    int delta = trainSignal.delta;
    state.trainList.get(id).id = id;  // 当該列車を取得
  }
}

int time = 0;

void draw() {
  communication.update();

  // 各車両について行う
  for (Train train : state.trainList) {
    int targetSpeed = getTargetSpeed(train);
    // MoveResult moveResult = state.trainList.get(train.id).move(targetSpeed);  // 適当な距離進ませる
    // timetableUpdate(train, moveResult);  // 時刻表を更新する
    communication.sendSpeed(train.id, targetSpeed);
    println(time + " SEND train=" + train.id + ", speed=" + targetSpeed);
  }

  // 各ポイントについて行う
  for (Junction junction : state.junctionList) {
    if (junctionControl(junction)) {  // ポイントを切り替えるべきか判定
      ServoState toggleResult = junction.toggle();  // ポイントを切り替える
      if (junction.servoId > -1 && toggleResult != ServoState.NoServo) {
        communication.sendToggle(junction.servoId, toggleResult);
        println(time + " SEND servo=" + junction.servoId + ", toggle=" + toggleResult);
      }
    }
  }

  // 車両から進んだ距離を取得し、シミュレーションを更新する
  while (communication.availableTrainSignal() > 0) {
    TrainSignal trainSignal = communication.receiveTrainSignal();
    int id = trainSignal.trainId;
    int delta = trainSignal.delta;
    Train train = state.trainList.get(id);
    MoveResult moveResult = train.move(delta);
    println(time + " RECEIVE train=" + id + ", delta=" + delta);
    timetableUpdate(train, moveResult);
  }
  
  // センサ入力で車両の位置補正を行う
  // センサ入力があったときに関数 positionAdjust(sensorId) を呼んでください
  if (keyPressed == true) {  // (デバッグ用)キーを押したらセンサ0の位置補正
    println("keyPressed");
    positionAdjust(0);
  }
  
  while (communication.availableSensorSignal() > 0) {
    int sensorId = communication.receiveSensorSignal();
    println(time + " RECEIVE sensor=" + sensorId);
    positionAdjust(sensorId);
  }
  
  // 描画
  display.draw(state);
  
  try{  // 一定時間待つ
    Thread.sleep(200);
  } catch(InterruptedException ex){
    ex.printStackTrace();
  }
  time += 200;
    
}
