import processing.serial.*;
import java.util.Queue;
import java.util.ArrayDeque;
import java.util.Map;

// ESP32 や Arduino との通信をまとめる。
// シミュレーションモードを使うと接続が無くてもある程度動作確認できる。
class Communication {
  boolean simulationMode;
  HashMap<Integer, Integer> simulationSpeedMap;
  Queue<Byte> simulationBuffer;
  PApplet parent;
  Serial esp32;  // ESP32 と Bluetooth でつながっている。
  Serial arduino;  // Arduino と有線でつながっている。
  
  Communication(PApplet parent) {
    this.parent = parent;
    simulationMode = false;
    simulationSpeedMap = new HashMap<Integer, Integer>();
    simulationSpeedMap.put(0, 255);
    simulationSpeedMap.put(1, 255);
    simulationBuffer = new ArrayDeque<Byte>();
  }
  
  void setup() {
    if (simulationMode) {
    } else {
      esp32 = new Serial(parent, "/dev/cu.ESP32-ESP32SPP", 115200);  // Mac
      // esp32 = new Serial(parent, "/dev/cu.Bluetooth-Incoming-Port", 115200);  // Macテスト用
      // esp32 = new Serial(parent, "COM8", 115200);  // Windows
      arduino = new Serial(parent, "", 9600);
    }
    updateSimulation();
  }
  
  void updateSimulation() {
    if (simulationMode) {
      for (Map.Entry<Integer, Integer> entry : simulationSpeedMap.entrySet()) {
        int trainId = entry.getKey();
        int speed = entry.getValue();
        if (speed > 0) {
          simulationBuffer.add((byte) trainId);
        }
      }
    }
  }
  
  int available() {
    if (simulationMode) {
      return simulationBuffer.size();
    } else {
      return esp32.available() + arduino.available();
    }
  }
  
  int read() {
    if (simulationMode) {
      if (simulationBuffer.size() > 0) {
        int id = simulationBuffer.remove();
        return id;
      } else {
        return 0;
      }
    } else {
      if (esp32.available() > 0) {
        return esp32.read();
      } else if (arduino.available() > 0) {
        return arduino.read();
      } else {
        return 0;
      }
    }
  }
  
  // 指定した車両に目標速度を送る。
  void sendSpeed(int trainId, int speed) {
    if (simulationMode) {
      simulationSpeedMap.put(trainId, speed);
    } else {
      esp32.write(speed);
    }
  }
  
  // 指定したポイントに切替命令を送る。
  void sendToggle(int junctionId) {
    if (simulationMode) {
    } else {
      arduino.write(junctionId);
    }
  }
}
