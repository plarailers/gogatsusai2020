import processing.serial.*;
import java.util.Queue;
import java.util.ArrayDeque;
import java.util.Map;

// ESP32 や Arduino との通信をまとめる。
// シミュレーションモードを使うと接続が無くてもある程度動作確認できる。
class Communication {
  boolean simulationMode;
  HashMap<Integer, Integer> simulationSpeedMap;
  PApplet parent;
  Serial esp32;  // ESP32 と Bluetooth でつながっている。
  Serial arduino;  // Arduino と有線でつながっている。
  Queue<TrainSignal> trainSignalBuffer;
  Queue<Integer> sensorSignalBuffer;
  
  Communication(PApplet parent) {
    this.parent = parent;
    simulationMode = false;
    simulationSpeedMap = new HashMap<Integer, Integer>();
    simulationSpeedMap.put(0, 255);
    simulationSpeedMap.put(1, 255);
    trainSignalBuffer = new ArrayDeque<TrainSignal>();
    sensorSignalBuffer = new ArrayDeque<Integer>();
  }
  
  void setup() {
    if (simulationMode) {
    } else {
      esp32 = new Serial(parent, "/dev/cu.ESP32-ESP32SPP", 115200);  // Mac
      // esp32 = new Serial(parent, "/dev/cu.Bluetooth-Incoming-Port", 115200);  // Macテスト用
      // esp32 = new Serial(parent, "COM8", 115200);  // Windows
      arduino = new Serial(parent, "", 9600);
    }
    update();
  }
  
  void update() {
    if (simulationMode) {
      for (Map.Entry<Integer, Integer> entry : simulationSpeedMap.entrySet()) {
        int trainId = entry.getKey();
        int speed = entry.getValue();
        if (speed > 0) {
          trainSignalBuffer.add(new TrainSignal(trainId, speed));
        }
      }
    } else {
      while (esp32.available() > 0) {
        trainSignalBuffer.add(new TrainSignal(0, esp32.read()));
      }
      while (arduino.available() > 0) {
        sensorSignalBuffer.add(arduino.read());
      }
    }
  }
  
  int availableTrainSignal() {
    return trainSignalBuffer.size();
  }
  
  TrainSignal receiveTrainSignal() {
    return trainSignalBuffer.remove();
  }
  
  int availableSensorSignal() {
    return sensorSignalBuffer.size();
  }
  
  int receiveSensorSignal() {
    return sensorSignalBuffer.remove();
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

class TrainSignal {
  int trainId;
  int delta;
  TrainSignal(int trainId, int delta) {
    this.trainId = trainId;
    this.delta = delta;
  }
}
