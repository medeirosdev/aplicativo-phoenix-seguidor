import 'package:flutter/foundation.dart';
import '../models/robot_state.dart';
import '../models/race_config.dart';
import '../models/pid_params.dart';

class RobotProvider extends ChangeNotifier {
  RobotState _robotState = RobotState.initialization;
  RaceConfig _raceConfig = RaceConfig();
  PidParams _pidParams = PidParams.follower();
  double _batteryVoltage = 0.0;
  BatteryStatus _batteryStatus = BatteryStatus.unknown;

  // Virtual Line
  double _lookAhead = 0.12;
  double _vlGain = 2.0;
  bool _driftCorrection = false;
  int _smoothWindow = 2;

  // ─── Getters ───
  RobotState get robotState => _robotState;
  RaceConfig get raceConfig => _raceConfig;
  PidParams get pidParams => _pidParams;
  double get batteryVoltage => _batteryVoltage;
  BatteryStatus get batteryStatus => _batteryStatus;
  double get lookAhead => _lookAhead;
  double get vlGain => _vlGain;
  bool get driftCorrection => _driftCorrection;
  int get smoothWindow => _smoothWindow;

  // ─── Race Config ───
  void setRacingMode(RacingMode mode) {
    _raceConfig = _raceConfig.copyWith(mode: mode);
    // Atualiza PID com preset do modo
    if (mode == RacingMode.lineFollower) {
      _pidParams = PidParams.follower();
    } else if (mode == RacingMode.lineChaser) {
      _pidParams = PidParams.chaser();
    }
    notifyListeners();
  }

  void setAcceleration(bool enabled) {
    _raceConfig = _raceConfig.copyWith(accelerationEnabled: enabled);
    notifyListeners();
  }

  void setEsc(bool enabled) {
    _raceConfig = _raceConfig.copyWith(escEnabled: enabled);
    notifyListeners();
  }

  // ─── PID ───
  void updatePidParams(PidParams params) {
    _pidParams = params;
    notifyListeners();
  }

  void setKp(double value) {
    _pidParams.kp = value;
    notifyListeners();
  }

  void setKd(double value) {
    _pidParams.kd = value;
    notifyListeners();
  }

  void setSpeed(double value) {
    _pidParams.speed = value;
    notifyListeners();
  }

  void setEscPower(double value) {
    _pidParams.escPower = value;
    notifyListeners();
  }

  void setAccelStep(double value) {
    _pidParams.accelStep = value;
    notifyListeners();
  }

  void loadPreset(String preset) {
    switch (preset) {
      case 'follower':
        _pidParams = PidParams.follower();
        break;
      case 'chaser':
        _pidParams = PidParams.chaser();
        break;
    }
    notifyListeners();
  }

  // ─── Virtual Line ───
  void setLookAhead(double value) {
    _lookAhead = value;
    notifyListeners();
  }

  void setVlGain(double value) {
    _vlGain = value;
    notifyListeners();
  }

  void setDriftCorrection(bool value) {
    _driftCorrection = value;
    notifyListeners();
  }

  void setSmoothWindow(int value) {
    _smoothWindow = value;
    notifyListeners();
  }

  // ─── Battery ───
  void updateBattery(double voltage) {
    _batteryVoltage = voltage;
    if (voltage <= 3.0) {
      _batteryStatus = BatteryStatus.usb;
    } else if (voltage <= 11.2) {
      _batteryStatus = BatteryStatus.low;
    } else if (voltage < 12.0) {
      _batteryStatus = BatteryStatus.medium;
    } else {
      _batteryStatus = BatteryStatus.high;
    }
    notifyListeners();
  }

  // ─── Robot State ───
  void setRobotState(RobotState state) {
    _robotState = state;
    notifyListeners();
  }
}
