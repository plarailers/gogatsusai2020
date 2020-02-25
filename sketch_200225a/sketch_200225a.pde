Display display;

void settings() {
  size(800, 500);
}

void setup() {
  display = new Display();
  display.setup();
}

void draw() {
  display.draw();
}
