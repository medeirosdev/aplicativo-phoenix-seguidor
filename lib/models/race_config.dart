import 'robot_state.dart';

class RaceConfig {
  RacingMode mode;
  bool accelerationEnabled;
  bool escEnabled;

  RaceConfig({
    this.mode = RacingMode.waiting,
    this.accelerationEnabled = false,
    this.escEnabled = false,
  });

  RaceConfig copyWith({
    RacingMode? mode,
    bool? accelerationEnabled,
    bool? escEnabled,
  }) {
    return RaceConfig(
      mode: mode ?? this.mode,
      accelerationEnabled: accelerationEnabled ?? this.accelerationEnabled,
      escEnabled: escEnabled ?? this.escEnabled,
    );
  }
}
