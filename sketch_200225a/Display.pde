class Display {
    int base = 0; // 初期時間
    int count; //スタートしてから経過した時間
    float x = 150, y = 100; //電車の初期位置
    //int d = 2; //一回の処理で進む距離
    int tmp; //調整用
    int train = 30; //電車の大きさ
    int left_rect = 150, up_rect = 100; // 線路の左上の点の座標
    int width = 200, height = 300; // 線路の横、縦のサイズ
    int all_rail = 2*width + 2*height; //線路の全長
    void setup(){
    textSize(30); // 文字の大きさ

    }
    void draw(float position_percentage){ //double position_percentage = 電車の位置のパーセント表記
        background(240);
        stroke(0);
        fill(255,255,255);
        rect(left_rect + width/2,up_rect + height/2,width,height);
        int ms = millis()/1000;
        // 以下で電車の座標を決定
        float position = all_rail * position_percentage;
        if (position <= width) {
            x = left_rect + position;
            y = up_rect;
        }
        else if (position <= width + height) {
            x = left_rect + width;
            y = up_rect + position - width;
        }
        else if (position <= 2 * width + height) {
            x = left_rect + width - (position - width - height);
            y = up_rect + height;
        }
        else if (position <= 2 * width + 2 * height){
            x = left_rect;
            y = up_rect + height - (position - 2 * width - height);
        }
        // 電車の描画
        stroke(255, 255, 255);
        fill(0);
        rectMode(CENTER);
        rect(x,y,train,train);
        // 時刻の描画
        fill(0);
        count = base + ms;
        text("time : "+count, 600, 400);
    }
}
