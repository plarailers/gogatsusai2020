// 列車制御に使う定数
static final int STOPMERGIN = 10;  // Junctionの何m手前で停止指令を出すか


// 【列車制御】列車meが先に進んでよいかを返す
Boolean canMove(Train me) {
  
  // 1. 先行列車が存在するsectionの手前で止める
  Section frontTrainSection = getFrontTrainSection(me);  // 先行列車のいるsectionを取得
  if (frontTrainSection.id == me.currentSection.targetJunction.getPointedSection().id) {
    if (me.currentSection.length - me.mileage < STOPMERGIN){
      return false;
    } else if (me.currentSection.hasStation) {  // 駅があった場合は駅で止めておく
      if (me.mileage >= me.currentSection.stationPosition) {
        return false;
      }
    }
  }

  // 2. 前方の分岐器がmeのいるsectionに繋がっていない場合は、分岐器の手前で止める
  Junction frontJunction = me.currentSection.targetJunction;  // すぐ前方のJunction
  if (me.currentSection.id != frontJunction.inSectionList.get(frontJunction.inSectionIndex).id) {
    if (me.currentSection.length - me.mileage < STOPMERGIN){
      return false;
    } else if (me.currentSection.hasStation) {  // 駅があった場合は駅で止めておく
      if (me.mileage >= me.currentSection.stationPosition) {
        return false;
      }
    }
  }

  // 3. 時刻表を参照し、出発時刻前の列車は止めておく

  return true;
}

// 列車meの先行列車がいるsectionを返す
Section getFrontTrainSection(Train me) {
  Section checkSection = me.currentSection.targetJunction.getPointedSection();
  while (detectTrain(checkSection) == null) {  // 先行列車が見つかるまで繰り返す
    checkSection = checkSection.targetJunction.getPointedSection();
  }
  return checkSection;
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
