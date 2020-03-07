/*class Node {
    int x;
    int y;

    Node(int x, int y) {
        this.x = x;
        this.y = y;
    }
}*/

class Display2 {
    int base = 0; // 初期時間
    int count; //スタートしてから経過した時間
    float x = 150, y = 100; //電車の初期位置
    //int d = 2; //一回の処理で進む距離
    int tmp; //調整用
    int train = 30; //電車の大きさ
    int left_rect = 150, up_rect = 100; // 線路の左上の点の座標
    int width = 200, height = 300; // 線路の横、縦のサイズ
    int station_width = 50, station_height = 150;
    int len_section0 = 2*width + 2*height - station_height; //セクション0の長さ
    int len_section1 = station_height;
    int len_section2 = station_height + 2*station_width;
    int junction0_y = up_rect + height/2 - station_height/2, junction1_y = up_rect + height/2 + station_height/2;
    void setup(){
        textSize(30); // 文字の大きさ

    }
    void draw(Train state_train){ //double position_percentage = 電車の位置のパーセント表記
        background(240);
        stroke(0);
        fill(255,255,255);
        line(left_rect, up_rect, left_rect+width, up_rect); //このへんはメインの線路
        line(left_rect + width, up_rect, left_rect + width, up_rect + height);
        line(left_rect + width, up_rect + height, left_rect, up_rect + height);
        line(left_rect, up_rect + height, left_rect, up_rect);
        line(left_rect - station_width, junction0_y, left_rect, junction0_y); //ここから駅
        line(left_rect - station_width, junction1_y, left_rect, junction1_y);
        line(left_rect - station_width, junction0_y, left_rect - station_width, junction1_y);
        
        int ms = millis()/1000;
        // 以下で電車の座標を決定
        int section_id = state_train.currentSection.id;
        int len = state_train.currentSection.length;
        float position;
        if (section_id == 0) {
            position = len_section0 * state_train.getPosition();
            if (position <= junction0_y - up_rect) { //junction0から上に移動
                x = left_rect;
                y = junction0_y - position;
            }
            else if (position <= junction0_y - up_rect + width) { //左上から右上に移動
                x = left_rect + position - (junction0_y - position);
                y = up_rect;
            }
            else if (position <= junction0_y - up_rect + width + height) { //右上から右下に移動
                x = left_rect + width;
                y = up_rect + position - (junction0_y - up_rect + width + height);
            }
            else { //左下からjunction1に移動
                x = left_rect;
                y = up_rect + height - position - (junction0_y - up_rect + 2 * width + height);
            }
        }
        else if (section_id == 1) {
            position = len_section1 * state_train.getPosition();
            x = left_rect;
            y = junction1_y - position;
        }
        else if (section_id == 2) {
            position = len_section2 * state_train.getPosition();
            if (position <= station_width) {
                x = left_rect - position;
                y = junction1_y;
            }
            else if (position <= station_width + station_height) {
                x = left_rect - station_width;
                y = junction1_y - (position - station_width);
            }
            else {
                x = left_rect - station_width + (position - (station_width + station_height));
                y = junction0_y;
            }
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
