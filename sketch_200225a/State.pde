class State {
  ArrayList<Junction> junctionList;
  ArrayList<Section> sectionList;
  Train train;
  ESP32 esp32;
  State() {
    junctionList = new ArrayList<Junction>();
    junctionList.add(new Junction(0));
    junctionList.add(new Junction(1));
    sectionList = new ArrayList<Section>();
    sectionList.add(new Section(0, 80, 0, 1));
    sectionList.add(new Section(1, 20, 1, 0));
    sectionList.add(new Section(2, 20, 1, 0));
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
  
  // 返り値：現在の区間の何割のところにいるか [0, 1)
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
      currentSection = currentSection.targetJunction.outSectionList.get(0);
      return true;
    }
    return false;
  }
}

static class Junction {
  static ArrayList<Junction> all = new ArrayList<Junction>();
  
  int id;
  ArrayList<Section> inSectionList;
  ArrayList<Section> outSectionList;
  
  Junction(int id) {
    all.add(this);
    this.id = id;
    inSectionList = new ArrayList<Section>();
    outSectionList = new ArrayList<Section>();
  }
  
  static Junction getById(int id) {
    for (Junction j : all) {
      if (j.id == id) {
        return j;
      }
    }
    return null;
  }
}

class Section {
  int id;
  int length = 0;
  Junction sourceJunction;
  Junction targetJunction;
  
  Section(int id, int length, int sourceId, int targetId) {
    this.id = id;
    this.length = length;
    this.sourceJunction = Junction.getById(sourceId);
    this.sourceJunction.outSectionList.add(this);
    this.targetJunction = Junction.getById(targetId);
    this.targetJunction.inSectionList.add(this);
  }
}
