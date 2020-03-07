class ESP32 {
  boolean isSimulated = false;
  
  void simulate() {
    isSimulated = true;
  }
  
  void sendGo() {
    println("GO");
  }
  
  void sendStop() {
    println("STOP");
  }
}
