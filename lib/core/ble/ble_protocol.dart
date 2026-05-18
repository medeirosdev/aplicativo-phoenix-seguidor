/// Protocolo de comandos BLE para o robo Bia.
/// Todos os comandos terminam com '\r'.
class BleProtocol {
  static const String terminator = '\r';

  // ─── Configuracao (prefixo C) ───
  static String setLineFollower() => 'CLF$terminator';
  static String setLineChaser() => 'CLC$terminator';
  static String setVirtualLine() => 'CVL$terminator';
  static String setAccelerationOff() => 'CA0$terminator';
  static String setAccelerationOn() => 'CA1$terminator';
  static String setEscOff() => 'CE0$terminator';
  static String setEscOn() => 'CE1$terminator';
  static String applyConfig() => 'COK$terminator';
  static String setTestMode() => 'CTS$terminator';
  static String setBlankSpace() => 'CBS$terminator';

  // ─── Debug (prefixo D) ───
  static String debugBattery() => 'DBT$terminator';
  static String debugIR() => 'DIR$terminator';
  static String debugFrontalSensors() => 'DFS$terminator';
  static String debugOff() => 'DOF$terminator';

  // ─── Calibracao (prefixo K) ───
  static String calibrateManual() => 'KM0$terminator';
  static String calibrateManualEeprom() => 'KME$terminator';
  static String calibrateFromEeprom() => 'KEE$terminator';
  static String startCalibration() => 'KOK$terminator';

  // ─── Start/Stop (prefixo S) ───
  static String startRace() => 'SST$terminator';
  static String stopRace() => 'SSP$terminator';

  // ─── PID (prefixo P) ───
  static String setKp(double value) => 'PP,${value.toStringAsFixed(3)}$terminator';
  static String setKd(double value) => 'PD,${value.toStringAsFixed(4)}$terminator';
  static String setSpeed(double value) => 'PV,${value.toStringAsFixed(2)}$terminator';
  static String setEscPower(double value) => 'PE,${value.toStringAsFixed(1)}$terminator';
  static String setAccelStep(double value) => 'PA,${value.toStringAsFixed(2)}$terminator';
  static String consultPid() => 'PC$terminator';

  // ─── Giroscopio (prefixo G) ───
  static String calibrateGyro() => 'GC$terminator';
  static String enableMapping() => 'GMAP$terminator';
  static String dumpMap() => 'GDUMP$terminator';

  // ─── Linha Virtual (prefixo V) ───
  static String setLookAhead(double meters) => 'VL,${meters.toStringAsFixed(3)}$terminator';
  static String setGain(double gain) => 'VG,${gain.toStringAsFixed(2)}$terminator';
  static String smoothTrajectory(int window) => 'VS,$window$terminator';
  static String computeSpeedProfile(double maxV, double minV, double threshold) =>
      'VP,${maxV.toStringAsFixed(1)},${minV.toStringAsFixed(1)},${threshold.toStringAsFixed(0)}$terminator';
  static String setDriftCorrection(bool enabled) => 'VD,${enabled ? 1 : 0}$terminator';
  /// VB,ratio — proporcao da linha fisica no blend (0.0=pure PP, 1.0=pure linha)
  static String setLineBlend(double ratio) => 'VB,${ratio.toStringAsFixed(2)}$terminator';
  /// VK,kp — ganho proporcional do sensor de linha no blend
  static String setLineKp(double kp) => 'VK,${kp.toStringAsFixed(3)}$terminator';
  static String consultVirtualLine() => 'VC$terminator';
  /// VM,dist,angle — resolucao do mapa (distancia em m, angulo em graus)
  /// Ex: setMapResolution(0.02, 10.0) = 2cm OU 10° (padrao)
  ///     setMapResolution(0.02, 5.0)  = 2cm OU 5°  (mais denso em curvas)
  ///     setMapResolution(0.01, 3.0)  = 1cm OU 3°  (maximo detalhe)
  static String setMapResolution(double distM, double angleDeg) =>
      'VM,${distM.toStringAsFixed(3)},${angleDeg.toStringAsFixed(1)}$terminator';

  // ─── Telemetria (prefixo T) ───
  static String requestTelemetry() => 'TP$terminator';

  // ─── Marcadores (prefixo M) ───
  static String countMarkers() => 'MM$terminator';

  // ─── Comando raw ───
  static String raw(String command, {bool addTerminator = true}) {
    if (addTerminator && !command.endsWith(terminator)) {
      return '$command$terminator';
    }
    return command;
  }
}
