import processing.serial.*;
import java.util.Queue;
import java.util.ArrayDeque;
import java.util.Map;

// シミュレーションモードを使うと接続が無くてもある程度動作確認できる。
class Communication {
  boolean simulationMode;
  HashMap<Integer, Integer> simulationSpeedMap;
  Queue<Byte> simulationBuffer;
  PApplet parent;
  Serial port;
  
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
      port = new Serial(parent, "/dev/cu.ESP32-ESP32SPP", 115200);  // Mac
      // port = new Serial(parent, "/dev/cu.Bluetooth-Incoming-Port", 115200);  // Macテスト用
      // port = new Serial(parent, "COM8", 115200);  // Windows
    }
    updateSimulation();
  }
  
  void updateSimulation() {
    if (simulationMode) {
      for(Map.Entry<Integer, Integer> entry : simulationSpeedMap.entrySet()) {
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
      return port.available();
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
      return port.read();
    }
  }
  
  void write(int data) {
    if (simulationMode) {
    } else {
      port.write(data);
    }
  }
  
  // 指定した trainId に目標速度を送る。
  void sendSpeed(int trainId, int speed) {
    if (simulationMode) {
      simulationSpeedMap.put(trainId, speed);
    } else {
      write((int) 'T');
      write(speed);
    }
  }
  
  // 指定した junctionId に切替命令を送る。
  void sendToggle(int junctionId) {
    if (simulationMode) {
    } else {
      write((int) 'J');
      write(junctionId);
    }
  }
}
