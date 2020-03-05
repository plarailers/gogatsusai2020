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

void settings() {
  size(800, 500);
}

void setup() {
  state = new State();
  display = new Display();
  display.setup();
}

void draw() {
  display.draw((float) state.train.mileage / state.section.length);
  text("train : " + state.train.mileage, 600, 450);
}

void keyPressed() {
  if (key == ' ') {
    state.train.mileage += 1;
    if (state.train.mileage >= state.section.length) {
      state.train.mileage -= state.section.length;
    }
  }
  if (key == ENTER) {
    state.train.mileage = 0;
  }
}
