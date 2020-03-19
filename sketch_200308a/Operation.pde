// 列車制御に使う定数
static final int STOPMERGIN = 20;  // Junctionの何m手前で停止するか
static final int TRAINLENGTH = 30;  // 列車1編成の長さ

// 【列車制御】指定された列車の停止点を返す
StopPoint getStopPoint(Train me) {
  Info info = timetable.getByTrainId(me.id);

  // まず、先行列車位置と分岐器から停止点を求める
  Section section = getAvailableSection(me);
  int mileage = section.length - STOPMERGIN;

  // 現在のセクションに駅があり、まだ出発or通過していない場合
  if (me.currentSection.hasStation && me.mileage <= me.currentSection.stationPosition) {
    // 駅で停車中なら、出発時刻が来るまでは停止点を駅に設定
    if (info != null && info.isDeparture() == true && time/1000 < info.time) {
      section = me.currentSection;
      mileage = section.stationPosition;
    }
    // 出発時刻を過ぎても、進路が開通していなければ駅で待つ
    if (section == me.currentSection) {
      mileage = section.stationPosition;
    }
    // 到着前なら停止点を駅に設定
    if (info != null && info.isArrival() == true) {
      section = me.currentSection;
      mileage = section.stationPosition;
    }
  // 現在のセクションに出発or通過すべき駅がない場合
  } else {
    // 停止点へ向かって進んでいき、途中に停車駅があればそこを停止点とする
    Section testSection = me.currentSection.targetJunction.getPointedSection();
    while (testSection.id != section.targetJunction.getPointedSection().id) {
      if (testSection.hasStation) {  // 駅があったら
        if (info != null && info.isArrival()) {  // 到着駅なら
          section = testSection;
          mileage = section.stationPosition;
          break;
        }
      }
      testSection = testSection.targetJunction.getPointedSection();  // 次のsectionへ進む
    }
  }

  StopPoint stopPoint = new StopPoint(section, mileage);
  return stopPoint;
}

// 【ポイント制御】時刻表に応じて各Junctuionをまとめて制御する
void junctionControl() {
  for (Junction junction : state.junctionList) {
    Section inSection = junction.getInSection();
    Section outSection = junction.getPointedSection();
    
    // 列車が分岐器上にいないときに操作を行う
    Train trainOnJunction = detectTrain(outSection);
    if (trainOnJunction == null || trainOnJunction.mileage > TRAINLENGTH) {
      
      // in1->out2 という分岐器の場合、到着する列車の番線に合わせる
      if (junction.inSectionList.size() == 1 && junction.outSectionList.size() > 1) {
        Train inTrain = detectTrain(junction.getInSection());  // 分岐器へ進入する列車を取得
        if (inTrain != null) {  // 列車が近づいて来ているとき
          Info info = timetable.getByTrainId(inTrain.id);  // 近づいてくる列車の時刻情報を取得
          Section arrTrack = Station.getById(info.stationId).trackList.get(info.trackId);  // 近づいてくる列車の着発番線を取得
          while (arrTrack.id != junction.getPointedSection().id) {  // 到着番線と、現在開通している番線が違えば、合わせる
            Junction.getById(junction.id).toggle();
            println("toggled:Junction" + junction.id);
          }
        }

      // in2->out1 という分岐器の場合、
      } else if (junction.inSectionList.size() > 1 && junction.outSectionList.size() == 1) {
        // 現在開通している進路に列車がいる場合、この列車がいなくなるまで分岐器が動かないよう鎖錠
        Train inTrain = detectTrain(junction.getInSection());  // 分岐器開通方向の列車を取得
        if (inTrain != null) {
          // 鎖錠
          println("鎖錠:Junction"+junction.id);
        } else {
          // 鎖錠しない場合、最も早く出発or通過する列車の番線に合わせる
          Station station = getBelongStation(junction);  // junctionが属する駅を取得
          Info info = timetable.getDepartureByTrackId(station.id, station.getTrackIdBySection(inSection));  // とりあえず現在開通している番線の出発時刻情報を取得
          for (Section section : junction.inSectionList) {
            Info tmpInfo = timetable.getDepartureByTrackId(station.id, station.getTrackIdBySection(section));  // 各inSectionの到着時刻情報を取得
            if (info != null && tmpInfo != null && tmpInfo.time < info.time) {  // tmpInfo.timeのほうが早ければinfoを更新
              info = tmpInfo;
            } else if (info == null && tmpInfo != null) {
              info = tmpInfo;
            }
          }
          if (info != null) {  // <-このinfoは、最も早く出発or通過する列車の時刻情報
            while (junction.getInSection().id != station.trackList.get(info.trackId).id) {  // 出発番線と、現在開通している番線が異なれば、合わせる
              Junction.getById(junction.id).toggle();
              println("toggled:Junction" + junction.id);
            }
          }
        }
      }
    }
  }
}  

// 先行列車位置と分岐器の方向を基に、列車meが進んでよいsectionを返す
Section getAvailableSection(Train me) {
  Section currentSection = me.currentSection;
  Junction junction = me.currentSection.targetJunction;
  Section checkSection = me.currentSection.targetJunction.getPointedSection();
  // 先行列車がおらず、junctionが開通している間進む
  while (detectTrain(checkSection) == null && junction.inSectionList.get(junction.inSectionIndex).id == currentSection.id) {
    currentSection = checkSection;  // 次のsectionに進む
    junction = currentSection.targetJunction;
    checkSection = currentSection.targetJunction.getPointedSection();
  }
  return currentSection;
}

// あるsectionにいる列車を返す。列車がいなければnullを返す
Train detectTrain(Section section) {
  for (Train train : state.trainList) {  // 各列車がどのセクションにいるか調べ、引数と一致すれば返す
    if (train.currentSection.id == section.id) {
      return train;
    }
  }
  return null;
}

// Junctionが属する駅を返す
Station getBelongStation(Junction junction) {
  for (Station station : state.stationList) {
    for (int i = 1; i <= station.trackList.size(); i++) {
      if (station.trackList.get(i).sourceJunction.id == junction.id || station.trackList.get(i).targetJunction.id == junction.id) {
        return station;
      }
    }
  }
  return null;
}