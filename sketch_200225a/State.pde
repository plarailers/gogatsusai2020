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
    sectionList.add(new Section(0, 400, 0, 1));
    sectionList.add(new Section(1, 100, 1, 0));
    sectionList.add(new Section(2, 200, 1, 0));
    Section.getById(1).putStation(50);
    Section.getById(2).putStation(100);
    train = new Train(sectionList.get(0));
    esp32 = new ESP32();
  }
}

enum MoveResult {
  None,
  PassedJunction,
  PassedStation
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
  MoveResult move(int delta) {
    int prevMileage = mileage;
    mileage += delta;
    if (mileage >= currentSection.length) {  // 分岐点を通過したとき
      mileage -= currentSection.length;
      currentSection = currentSection.targetJunction.getPointedSection();
      currentSection.sourceJunction.toggle();
      return MoveResult.PassedJunction;
    }
    if (currentSection.hasStation) {
      int stationPosition = currentSection.stationPosition;
      if (prevMileage < stationPosition && stationPosition <= mileage) {  // 駅を通過したとき
        return MoveResult.PassedStation;
      }
    }
    return MoveResult.None;
  }
}

static class Junction {
  static ArrayList<Junction> all = new ArrayList<Junction>();
  
  int id;
  ArrayList<Section> inSectionList;
  ArrayList<Section> outSectionList;
  int outSectionIndex;
  
  Junction(int id) {
    all.add(this);
    this.id = id;
    inSectionList = new ArrayList<Section>();
    outSectionList = new ArrayList<Section>();
    outSectionIndex = 0;
  }
  
  void toggle() {
    outSectionIndex = (outSectionIndex + 1) % outSectionList.size();
  }
  
  Section getPointedSection() {
    return outSectionList.get(outSectionIndex);
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

static class Section {
  static ArrayList<Section> all = new ArrayList<Section>();
  
  int id;
  int length = 0;
  Junction sourceJunction;
  Junction targetJunction;
  boolean hasStation = false;
  int stationPosition = 0;
  
  Section(int id, int length, int sourceId, int targetId) {
    all.add(this);
    this.id = id;
    this.length = length;
    this.sourceJunction = Junction.getById(sourceId);
    this.sourceJunction.outSectionList.add(this);
    this.targetJunction = Junction.getById(targetId);
    this.targetJunction.inSectionList.add(this);
  }
  
  void putStation(int stationPosition) {
    this.hasStation = true;
    this.stationPosition = stationPosition;
  }
  
  static Section getById(int id) {
    for (Section s : all) {
      if (s.id == id) {
        return s;
      }
    }
    return null;
  }
}
