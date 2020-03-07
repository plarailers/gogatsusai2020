class Timetable {
  ArrayList<Info> infoList;
  Timetable() {
    infoList = new ArrayList<Info>();
    // （仮）10秒ごとに発車
    for (int i = 0; i < 20; i++) {
      infoList.add(new Info(InfoType.Departure, 5000 * i, i % 2));
    }
  }
  
  // (from, to] の時刻情報を全て得る
  ArrayList<Info> get(int from, int to) {
    ArrayList<Info> result = new ArrayList<Info>();
    for (Info info : infoList) {
      if (from < info.time && info.time <= to) {
        result.add(info);
      }
    }
    return result;
  }
}

enum InfoType {
  Arrival,   // 到着
  Departure  // 出発
}

class Info {
  InfoType type;  // 到着か出発か
  int time;       // 時刻
  int trainId;    // 列車ID
  Info(InfoType type, int time, int trainId) {
    this.type = type;
    this.time = time;
    this.trainId = trainId;
  }
  
  boolean isArrival() {
    return type == InfoType.Arrival;
  }
  
  boolean isDeparture() {
    return type == InfoType.Departure;
  }
}
