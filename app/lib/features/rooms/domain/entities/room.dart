class Room {
  final String id;
  final String label;
  final int pin;

  const Room({required this.id, required this.label, required this.pin});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Room &&
        other.id == id &&
        other.label == label &&
        other.pin == pin;
  }

  @override
  int get hashCode => Object.hash(id, label, pin);

  @override
  String toString() => 'Room(id: $id, label: $label, pin: $pin)';
}
