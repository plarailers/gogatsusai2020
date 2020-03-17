State state;
Timetable timetable;

void settings() {
  size(800, 500);
}

void setup() {
  state = new State();
  Junction.getById(1).toggle();
  timetable = new Timetable();
  state.esp32.isSimulated = true;
}

int prevTime = -1;

void draw() {
  state.esp32.updateSimulation();
  while (state.esp32.available() > 0) {  // 各列車について行う
    int id = state.esp32.read();  // 列車id取得
    Train train = state.trainList.get(id);  // 当該列車を取得
    
    Boolean canMove = canMove(train);  // この列車が前に進んでよいか判定
    if (canMove) {
      int delta = (int) random(5,10);  // ランダムな距離進ませる
      MoveResult moveResult = state.trainList.get(id).move(delta);
    }

    println("trainId=" + id + ", section=" + train.currentSection.id + ", mileage=" + train.mileage + ", canMove=" + canMove);
  }
  
  try{  // 一定時間待つ
    Thread.sleep(500);   
  } catch(InterruptedException ex){
    ex.printStackTrace();
  }  
    
}
