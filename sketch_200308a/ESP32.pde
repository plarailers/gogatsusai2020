class ESP32 {
  boolean isSimulated;
  ArrayList<Boolean> simulatedMoving;
  ArrayList<Byte> simulatedBuffer;
  
  ESP32() {
    isSimulated = false;
    simulatedMoving = new ArrayList<Boolean>();
    simulatedMoving.add(true);
    simulatedMoving.add(true);
    simulatedBuffer = new ArrayList<Byte>();
  }
  
  void updateSimulation() {
    if (isSimulated) {
      for (int i = 0; i < simulatedMoving.size(); i++) {
        if (simulatedMoving.get(i)) {
          simulatedBuffer.add((byte) i);
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
        byte id = simulatedBuffer.remove(0);
        return id;
      } else {
        return 0;
      }
    } else {
      return 0;
    }
  }
  
  void sendGo(int id) {
    if (isSimulated) {
      simulatedMoving.set(id, true);
      println(id + "< GO");
    }
  }
  
  void sendStop(int id) {
    if (isSimulated) {
      simulatedMoving.set(id, false);
      println(id + "< STOP");
    }
  }
}
