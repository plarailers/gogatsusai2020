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
  while (state.esp32.available() > 0) {  // 各列車について行う
    int id = state.esp32.read();  // 列車id取得
    Train train = state.trainList.get(id);  // 当該列車を取得

    StopPoint stopPoint = getStopPoint(train);  // 停止点を取得
  
    if (stopPoint.section != train.currentSection || train.mileage < stopPoint.mileage) {
      int delta = (int) random(10,15);  // ランダムな距離進ませる
      MoveResult moveResult = state.trainList.get(id).move(delta);
      
      // 出発処理
      if (timetable.getByTrainId(id).isDeparture()) {
        timetable.getByTrainId(id).used = true;  // 出発済に変更
        println("train" + id + " Departed");
      }
      
      // 到着・通過処理
      if (moveResult == MoveResult.PassedStation) {
        if (timetable.getByTrainId(id).isArrival()) {  // 到着なら停止位置を合わせる
          state.trainList.get(id).mileage = train.currentSection.stationPosition;
        }
        timetable.getByTrainId(id).used = true;  // 到着・通過済に変更
      }
    }

    println("time=" + time + ", trainId=" + id + ", section=" + train.currentSection.id + ", mileage=" + train.mileage + ", stopPoint=Section" + stopPoint.section.id + ":" + stopPoint.mileage);
  }

  junctionControl();  // ポイント制御

  display.draw(state);
  
  try{  // 一定時間待つ
    Thread.sleep(500);   
  } catch(InterruptedException ex){
    ex.printStackTrace();
  }

  time = millis();
    
}
