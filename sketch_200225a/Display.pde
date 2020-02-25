class Display {
  int base = 0; // 初期時間
  int count; //スタートしてから経過した時間
  int x = 150, y = 100; //電車の初期位置
  int d = 2; //一回の処理で進む距離
  int tmp; //調整用
  int train = 30; //電車の大きさ
  int left_rect = 150, up_rect = 100; // 線路の左上の点の座標
  int width = 200, height = 300; // 線路の横、縦のサイズ
  void setup(){
    textSize(30); // 文字の大きさ
  }
   
  void draw(){
    background(240);
    stroke(0);
    fill(255,255,255);
    rect(left_rect,up_rect,width,height);
    int ms = millis()/1000;
    println(ms);
    // 以下で電車の座標を決定
    if (y == up_rect) {
        if (x <= left_rect + width - d) {
          x += d;
        }
        else {
            tmp = d - (left_rect + width - x);
            x = left_rect + width;
            y += tmp;
        }
    }
    else if (y == up_rect + height) {
        if (x >= left_rect + d) {
            x -= d;
        }
        else {
            tmp = d - (x - left_rect);
            x = left_rect;
            y -= tmp;
        }
    }
    else if (x == left_rect) {
        if (y >= up_rect + d) {
            y -= d;
        }
        else {
            tmp = d - (y - up_rect);
            y = up_rect;
            x += tmp;
        }
    }
    else if (x == left_rect + width){
        if (y <= up_rect + height - d){
            y += d;
        }
        else {
            tmp = d - (up_rect + height - y);
            y = up_rect + height;
            x -= tmp;
        }
      }
    // 電車の描画
    stroke(255, 255, 255);
    fill(0);
    rect(x-train/2,y-train/2,train,train);
    // 時刻の描画
    fill(0);
    count = base + ms;
    text("time : "+count, 600, 400);
  }
}
