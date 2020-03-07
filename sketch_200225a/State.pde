class State {
  Section section;
  Train train;
  ESP32 esp32;
  State() {
    section = new Section(0, 100);
    train = new Train(section);
    esp32 = new ESP32();
    esp32.simulate();
  }
}

class Train {
  int mileage = 0;
  Section currentSection;
  
  Train(Section initialSection) {
    currentSection = initialSection;
  }
  
  float getPosition() {
    float position = (float) state.train.mileage / (float) state.section.length;
    return position;
  }
}

class Section {
  int length = 0;
  int id;
  
  Section(int id, int length) {
    this.id = id;
    this.length = length;
  }
}
