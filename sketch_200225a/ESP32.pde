class ESP32 {
  boolean isSimulated;
  boolean simulatedMoving;
  int simulatedAvailable;
  
  ESP32() {
    isSimulated = false;
    simulatedMoving = false;
    simulatedAvailable = 0;
  }
  
  void updateSimulation() {
    if (isSimulated) {
      if (simulatedMoving) {
        simulatedAvailable += 1;
      }
    }
  }
  
  int available() {
    if (isSimulated) {
      return simulatedAvailable;
    } else {
      return 0;
    }
  }
  
  byte read() {
    if (isSimulated) {
      if (simulatedAvailable > 0) {
        simulatedAvailable -= 1;
        return (byte) random(3);
      } else {
        return 0;
      }
    } else {
      return 0;
    }
  }
  
  void sendGo() {
    if (isSimulated) {
      simulatedMoving = true;
      println("< GO");
    }
  }
  
  void sendStop() {
    if (isSimulated) {
      simulatedMoving = false;
      println("< STOP");
    }
  }
}
