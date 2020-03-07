State state;
Display2 display;
Timetable timetable;

void settings() {
  size(800, 500);
}

void setup() {
  state = new State();
  display = new Display2();
  timetable = new Timetable();
  display.setup();
}

int prevTime = -1;

void draw() {
  display.draw(state.train);
  text("train : " + state.train.mileage, 600, 450);
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
  // タイヤ回転
  if (key == ' ') {
    state.train.mileage += 1;
    if (state.train.mileage >= state.section.length) {  // 駅を通過したとき
      state.train.mileage -= state.section.length;
      state.esp32.sendStop();
    }
  }
  // 駅に到着
  if (key == ENTER) {
    state.train.mileage = 0;
  }
}
