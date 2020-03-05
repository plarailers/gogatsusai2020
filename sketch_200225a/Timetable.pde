class Timetable {
  ArrayList<Info> infoList;
  Timetable() {
    infoList = new ArrayList<Info>();
    // （仮）10秒ごとに発車
    for (int i = 0; i < 10; i++) {
      infoList.add(new Info(InfoType.Departure, 10000 * i));
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
  Departure  // 発車
}

class Info {
  InfoType type;  // 到着か発信か
  int time;       // 時刻
  Info(InfoType type, int time) {
    this.type = type;
    this.time = time;
  }
  
  boolean isArrival() {
    return type == InfoType.Arrival;
  }
  
  boolean isDeparture() {
    return type == InfoType.Departure;
  }
}
