enum RobotConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
}

enum RobotState {
  initialization,
  configuration,
  calibration,
  preRace,
  race,
  decelerating,
  brake,
  stop,
  testings,
}

enum RacingMode {
  lineFollower('Line Follower'),
  lineChaser('Line Chaser'),
  virtualLine('Virtual Line'),
  waiting('Aguardando');

  final String label;
  const RacingMode(this.label);
}

enum BatteryStatus {
  high('Alta'),
  medium('Media'),
  low('Baixa'),
  usb('USB'),
  unknown('---');

  final String label;
  const BatteryStatus(this.label);
}
