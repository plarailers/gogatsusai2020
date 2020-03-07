class State {
  ArrayList<Section> sectionList;
  Train train;
  ESP32 esp32;
  State() {
    sectionList = new ArrayList<Section>();
    sectionList.add(new Section(0, 100));
    train = new Train(sectionList.get(0));
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
    float position = (float) mileage / (float) currentSection.length;
    return position;
  }
  
  // 引数：タイヤの回転数
  // 返り値：新しい区間に移ったかどうか
  boolean move(int delta) {
    mileage += delta;
    if (mileage >= currentSection.length) {  // 駅を通過したとき
      mileage -= currentSection.length;
      return true;
    }
    return false;
  }
}

class Junction {
  int id;
}

class Section {
  int id;
  int length = 0;
  
  Section(int id, int length) {
    this.id = id;
    this.length = length;
  }
}
