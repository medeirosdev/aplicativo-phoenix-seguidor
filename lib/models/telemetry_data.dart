class TelemetrySnapshot {
  final DateTime timestamp;
  final double distanceM;
  final double heading;
  final double batteryVoltage;
  final double sensorPosition;

  const TelemetrySnapshot({
    required this.timestamp,
    this.distanceM = 0,
    this.heading = 0,
    this.batteryVoltage = 0,
    this.sensorPosition = 0,
  });
}
