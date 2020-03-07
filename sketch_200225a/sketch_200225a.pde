State state;
Display display;
Timetable timetable;

void settings() {
  size(800, 500);
}

void setup() {
  state = new State();
  display = new Display();
  timetable = new Timetable();
  display.setup();
  state.esp32.isSimulated = true;
}

int prevTime = -1;

void draw() {
  state.esp32.updateSimulation();
  while (state.esp32.available() > 0) {
    int delta = state.esp32.read();
    MoveResult moveResult = state.trainList.get(0).move(delta);
    if (moveResult == MoveResult.PassedStation) {
      state.esp32.sendStop();
    }
  }
  display.draw(state.trainList.get(0));
  int time = millis();
  // 前回記録した時刻から現在時刻までの発着情報を取得
  for (Info info : timetable.get(prevTime, time)) {
    if (info.isDeparture()) {  // 出発
      state.esp32.sendGo();
    }
  }
  prevTime = time;
}

void keyPressed() {
  // シミュレーションモード
  if (key == 's') {
    state.esp32.isSimulated = !state.esp32.isSimulated;
  }
  // タイヤ回転
  if (key == ' ') {
    MoveResult moveResult = state.trainList.get(0).move(1);
    if (moveResult == MoveResult.PassedStation) {
      state.esp32.sendStop();
    }
  }
  // 駅に到着
  if (key == ENTER) {
    state.trainList.get(0).mileage = 0;
  }
}
