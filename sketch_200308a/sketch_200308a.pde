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
  communication = new Communication();
  communication.isSimulated = true;
  communication.updateSimulation();
  while (communication.available() > 0) {  // 各列車について行う
    int id = communication.read();  // 列車id取得
    state.trainList.get(id).id = id;  // 当該列車を取得
  }
}

int prevTime = -1;
int time = 0;

void draw() {
  communication.updateSimulation();

  // 各列車について行う
  for (Train train : state.trainList) {
    int targetSpeed = getTargetSpeed(train);
    MoveResult moveResult = state.trainList.get(train.id).move(targetSpeed/20);  // 適当な距離進ませる
    timetableUpdate(train, targetSpeed, moveResult);  // 時刻表を更新する
    communication.sendSpeed(train.id, targetSpeed);
  }

  // 各ポイントについて行う
  for (Junction junction : state.junctionList) {
    if (junctionControl(junction)) {  // ポイントを切り替えるべきか判定
      Junction.getById(junction.id).toggle();  // ポイントを切り替える
      communication.sendToggle(junction.id);
    }
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
