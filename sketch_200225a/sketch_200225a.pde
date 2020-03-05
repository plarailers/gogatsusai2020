class State {
  Train train;
  Section section;
  State() {
    train = new Train();
    section = new Section(100);
  }
}

class Train {
  int mileage = 0;
}

class Section {
  int length = 0;
  Section(int length) {
    this.length = length;
  }
}

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
}

int prevTime = -1;

void draw() {
  float position = (float) state.train.mileage / (float) state.section.length;
  display.draw(position);
  text("train : " + state.train.mileage, 600, 450);
  int time = millis();
  // 前回記録した時刻から現在時刻までの発着情報を取得
  for (Info info : timetable.get(prevTime, time)) {
    if (info.isDeparture()) {  // 出発
      println("GO", time);
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
      println("STOP");
    }
  }
  // 駅に到着
  if (key == ENTER) {
    state.train.mileage = 0;
  }
}
