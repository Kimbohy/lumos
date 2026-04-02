const int PINS[] = {2, 6, 8, 13};
const int PIN_COUNT = 4;

void setup() {
  Serial.begin(9600);
  for (int i = 0; i < PIN_COUNT; i++) {
    pinMode(PINS[i], OUTPUT);
    digitalWrite(PINS[i], LOW);
  }
  Serial.println("READY");
}

void loop() {
  if (Serial.available()) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();

    int sep = cmd.indexOf(':');
    if (sep == -1) {
      Serial.println("ERROR:FORMAT");
      return;
    }

    int pin = cmd.substring(0, sep).toInt();
    String action = cmd.substring(sep + 1);
    action.toUpperCase();

    // vérifier que le pin est autorisé
    bool valid = false;
    for (int i = 0; i < PIN_COUNT; i++) {
      if (PINS[i] == pin) { valid = true; break; }
    }

    if (!valid) {
      Serial.println("ERROR:PIN");
      return;
    }

    if (action == "ON") {
      digitalWrite(pin, HIGH);
      Serial.println("OK");
    } else if (action == "OFF") {
      digitalWrite(pin, LOW);
      Serial.println("OK");
    } else {
      Serial.println("ERROR:ACTION");
    }
  }
}