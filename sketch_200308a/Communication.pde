import java.util.Queue;
import java.util.ArrayDeque;
import java.util.Map;

class Communication {
  boolean isSimulated;
  HashMap<Integer, Integer> simulatedSpeed;
  Queue<Byte> simulatedBuffer;
  
  Communication() {
    isSimulated = false;
    simulatedSpeed = new HashMap<Integer, Integer>();
    simulatedSpeed.put(0, 255);
    simulatedSpeed.put(1, 255);
    simulatedBuffer = new ArrayDeque<Byte>();
  }
  
  void updateSimulation() {
    if (isSimulated) {
      for(Map.Entry<Integer, Integer> entry : simulatedSpeed.entrySet()) {
        int trainId = entry.getKey();
        int speed = entry.getValue();
        if (speed > 0) {
          simulatedBuffer.add((byte) trainId);
        }
      }
    }
  }
  
  int available() {
    if (isSimulated) {
      return simulatedBuffer.size();
    } else {
      return 0;
    }
  }
  
  byte read() {
    if (isSimulated) {
      if (simulatedBuffer.size() > 0) {
        byte id = simulatedBuffer.remove();
        return id;
      } else {
        return 0;
      }
    } else {
      return 0;
    }
  }
  
  void write(byte data) {
  }
  
  void sendSpeed(int trainId, int speed) {
    if (isSimulated) {
      simulatedSpeed.put(trainId, speed);
    }
    write((byte) 'T');
    write((byte) speed);
  }
  
  void sendToggle(int junctionId) {
    write((byte) 'J');
    write((byte) junctionId);
  }
}
