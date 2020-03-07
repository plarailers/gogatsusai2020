class Node {
    float x;
    float y;

    Node(float x, float y) {
        this.x = x;
        this.y = y;
    }

    void set(float x, float y) {
        this.x = x;
        this.y = y;
    }
}

class Display {
    int base = 0; // 初期時間
    int count; //スタートしてから経過した時間
    Node train_position = new Node(150, 100);//電車の初期位置
    //int d = 2; //一回の処理で進む距離
    float tmp; //調整用
    int train = 30; //電車の大きさ
    Node node0 = new Node(150, 100); // 線路の左上の点の座標¥
    int width = 200, height = 300; // 線路の横、縦のサイズ
    int station_width = 50, station_height = 150; // 駅の横、縦のサイズ
    Node node1 = new Node(node0.x + width, node0.y);
    Node node2 = new Node(node1.x, node0.y + height);
    Node node3 = new Node(node0.x, node2.y);
    Node node4 = new Node(node0.x, node0.y + height/2 + station_height/2);
    Node node5 = new Node(node0.x - station_width, node4.y);
    Node node6 = new Node(node5.x, node0.y + height/2 - station_height/2);
    Node node7 = new Node(node0.x, node6.y);
    int len_section0 = 2*width + 2*height - station_height; //セクション0の長さ
    int len_section1 = station_height;
    int len_section2 = station_height + 2*station_width;
    int space = 20;
    void setup(){
        textSize(30); // 文字の大きさ

    }
    void draw(Train state_train){ //double position_percentage = 電車の位置のパーセント表記
        background(240);
        stroke(0);
        fill(255,255,255);
        line(node0.x, node0.y, node1.x, node1.y); //このへんはメインの線路
        line(node1.x, node1.y, node2.x, node2.y);
        line(node2.x, node2.y, node3.x, node3.y);
        line(node3.x, node3.y, node0.x, node0.y);
        line(node4.x, node4.y, node5.x, node5.y); //ここから駅
        line(node5.x, node5.y, node6.x, node6.y);
        line(node6.x, node6.y, node7.x, node7.y);
        rect((node0.x + node5.x)/2, (node0.y + node3.y)/2, station_width - space, station_height - space);
        
        int ms = millis()/1000;
        // 以下で電車の座標を決定
        int section_id = state_train.currentSection.id;
        int len = state_train.currentSection.length;
        float position;
        if (section_id == 0) {
            position = len_section0 * state_train.getPosition();
            if (position <= node7.y - node0.y) { //junction0から上に移動
                tmp = node7.y - position;
                train_position.set(node0.x, tmp);
            }
            else if (position <= node7.y - node0.y + width) { //左上から右上に移動
                tmp = position - (node7.y - node0.y);
                train_position.set(node0.x + tmp, node0.y);
            }
            else if (position <= node7.y - node0.y + width + height) { //右上から右下に移動
                tmp = position - (node7.y - node0.y + width);
                train_position.set(node1.x, node1.y + tmp);
            }
            else if (position <= node7.y - node0.y + 2*width + height) { //右下から左下に移動
                tmp = position - (node7.y - node0.y + width + height);
                train_position.set(node2.x - tmp, node2.y);
            }
            else { //左下からjunction1に移動
                tmp = position - (node7.y - node0.y + 2*width + height);
                train_position.set(node3.x, node3.y - tmp);
            }
        }
        else if (section_id == 1) {
            position = len_section1 * state_train.getPosition();
            train_position.set(node4.x, node4.y - position);
        }
        else if (section_id == 2) {
            position = len_section2 * state_train.getPosition();
            if (position <= station_width) {
                tmp = position;
                train_position.set(node4.x - tmp, node4.y);
            }
            else if (position <= station_width + station_height) {
                tmp = position - station_width;
                train_position.set(node5.x, node5.y - tmp);
            }
            else {
                tmp = position - (station_width + station_height);
                train_position.set(node6.x + tmp, node6.y);
            }
        }
        // 電車の描画
        stroke(255, 255, 255);
        fill(0);
        rectMode(CENTER);
        rect(train_position.x,train_position.y,train,train);
        // 時刻の描画
        fill(0);
        count = base + ms;
        text("time : "+count, 600, 400);
        }
}
