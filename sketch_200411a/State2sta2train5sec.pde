static final float STRAIGHT_UNIT = 21.5;
static final float CURVE_UNIT = 16.9;

// 2駅+1車両 テスト用
class State {
  ArrayList<Junction> junctionList;
  ArrayList<Section> sectionList;
  ArrayList<Train> trainList;
  ArrayList<Station> stationList;
  ArrayList<Sensor> sensorList;
  //  ------この部分が線路形状と車両の配置を定義する----------
  State() {
    junctionList = new ArrayList<Junction>();
    junctionList.add(new Junction(0, -1));
    junctionList.add(new Junction(1, 1));
    junctionList.add(new Junction(2, 0));
    junctionList.add(new Junction(3, -1));
    sectionList = new ArrayList<Section>();
    sectionList.add(new Section(0, (int)(STRAIGHT_UNIT * 5.5), 3, 0));
    sectionList.add(new Section(1, (int)(STRAIGHT_UNIT * 5 + CURVE_UNIT * 4), 0, 1));
    sectionList.add(new Section(2, (int)(STRAIGHT_UNIT * 5.5), 1, 2));
    sectionList.add(new Section(3, (int)(STRAIGHT_UNIT * 5.5), 1, 2));
    sectionList.add(new Section(4, (int)(STRAIGHT_UNIT * 3 + CURVE_UNIT * 4), 2, 3));
    // 場合によっては、着発番線に合わせてここにtoggleを挟む必要がある
    sensorList = new ArrayList<Sensor>();
    sensorList.add(new Sensor(0, 1, (int)(STRAIGHT_UNIT * 2.5 + CURVE_UNIT * 2)));
    sensorList.add(new Sensor(1, 4, (int)(STRAIGHT_UNIT * 1.5 + CURVE_UNIT * 2)));
    stationList = new ArrayList<Station>();
    stationList.add(new Station(0, "A"));  // A駅を追加
    stationList.add(new Station(1, "B"));  // B駅を追加
    Station.getById(0).setTrack(1, 0, (int)(STRAIGHT_UNIT * 3));  // 駅0の1番線はSection0
    Station.getById(1).setTrack(1, 2, (int)(STRAIGHT_UNIT * 3));  // 駅1の1番線はsection2
    Station.getById(1).setTrack(2, 3, (int)(STRAIGHT_UNIT * 3));  // 駅1の2番線はsection3
    trainList = new ArrayList<Train>();
    trainList.add(new Train(Station.getById(0).trackList.get(1), (int)(STRAIGHT_UNIT * 3)));  // 駅0の1番線に配置
    trainList.add(new Train(Station.getById(1).trackList.get(1), (int)(STRAIGHT_UNIT * 3)));  // 駅1の1番線に配置
    // --------------------------------------------
  }
}

enum MoveResult {
  None,
  PassedJunction,
  PassedStation
}

class Train {
  int id;
  int mileage = 0;
  int targetSpeed = 0;
  Section currentSection;
  
  Train(Section initialSection, int initialPosition) {
    currentSection = initialSection;
    mileage = initialPosition;
  }
  
  // 返り値：現在の区間の何割のところにいるか [0, 1)
  float getPosition() {
    float position = (float) mileage / (float) currentSection.length;
    return position;
  }
  
  // 引数：進んだ距離
  // 返り値：新しい区間に移ったかどうか
  MoveResult move(int delta) {
    int prevMileage = mileage;
    mileage += delta;
    if (mileage >= currentSection.length) {  // 分岐点を通過したとき
      mileage -= currentSection.length;
      currentSection = currentSection.targetJunction.getPointedSection();
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
  int servoId;
  ArrayList<Section> inSectionList;
  ArrayList<Section> outSectionList;
  int inSectionIndex;
  int outSectionIndex;
  
  Junction(int id, int servoId) {
    all.add(this);
    this.id = id;
    this.servoId = servoId;
    inSectionList = new ArrayList<Section>();
    outSectionList = new ArrayList<Section>();
    inSectionIndex = 0;
    outSectionIndex = 0;
  }
  
  void toggle() {
    if (inSectionList.size() > 1) {
      inSectionIndex = (inSectionIndex + 1) % inSectionList.size();
    } else {
      outSectionIndex = (outSectionIndex + 1) % outSectionList.size();
    }
  }
  
  Section getPointedSection() {
    return outSectionList.get(outSectionIndex);
  }

  Section getInSection() {
    return inSectionList.get(inSectionIndex);
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
  
  public void putStation(int stationPosition) {
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

static class Station {
  static ArrayList<Station> all = new ArrayList<Station>();
  
  int id;
  String name;
  HashMap<Integer, Section> trackList;  // 連想配列:番線とセクションを対応
  
  Station(int id, String name) {
    all.add(this);
    this.id = id;
    this.name = name;
    trackList = new HashMap<Integer, Section>();
  }
  
  void setTrack(int trackId, int sectionId, int stationPosition) {
    Section.getById(sectionId).putStation(stationPosition);  // 駅の追加
    this.trackList.put(trackId, Section.getById(sectionId));  // 番線と紐づけ
  }

  int getTrackIdBySection(Section section) {
    for (Station station : all) {
      for (int i = 1; i <= station.trackList.size(); i++) {
        if (station.trackList.get(i).id == section.id) {
          return i;
        }
      }
    }
    return 0;
  }

  static Station getBySection(Section section) {
    for (Station s : all) {
      for (int i = 1; i <= s.trackList.size(); i++) {
        if (s.trackList.get(i).id == section.id) {
          return s;
        }
      }
    }
    return null;
  }
  
  static Station getById(int id) {
    for (Station s : all) {
      if (s.id == id) {
        return s;
      }
    }
    return null;
  }
}

static class Sensor {
  static ArrayList<Sensor> all = new ArrayList<Sensor>();

  int id;
  Section belongSection;  // センサが属するセクション
  int position = 0;  // センサの位置

  Sensor(int id, int sectionId, int position) {
    all.add(this);
    this.id = id;
    this.belongSection = Section.getById(sectionId);
    this.position = position;
  }

  static Sensor getById(int id) {
    for (Sensor s : all) {
      if (s.id == id) {
        return s;
      }
    }
    return null;
  }
}

class StopPoint {  // 停止点情報
  Section section;
  int mileage;
  StopPoint(Section section, int mileage) {
    this.section = section;
    this.mileage = mileage;
  }
}
