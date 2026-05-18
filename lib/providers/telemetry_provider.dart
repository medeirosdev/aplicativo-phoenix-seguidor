import 'package:flutter/foundation.dart';
import '../models/track_point.dart';
import '../models/telemetry_data.dart';

class TelemetryProvider extends ChangeNotifier {
  final List<TrackPoint> _trackPoints = [];
  final List<TelemetrySnapshot> _snapshots = [];
  bool _isReceivingMap = false;
  final StringBuffer _csvBuffer = StringBuffer();

  // ─── Getters ───
  List<TrackPoint> get trackPoints => List.unmodifiable(_trackPoints);
  List<TelemetrySnapshot> get snapshots => List.unmodifiable(_snapshots);
  bool get isReceivingMap => _isReceivingMap;
  bool get hasTrack => _trackPoints.isNotEmpty;

  double get totalDistance =>
      _trackPoints.isNotEmpty ? _trackPoints.last.distanceM : 0;

  double get maxCurvature => _trackPoints.isEmpty
      ? 0
      : _trackPoints
          .map((p) => p.curvatureDps.abs())
          .reduce((a, b) => a > b ? a : b);

  // ─── Processar dados recebidos ───
  //
  // Firmware envia dois tipos de mensagem:
  //
  // 1. GDUMP (mapa completo):
  //    "--- INICIO CSV MAPA ---\nIndex;Dist(m);Yaw(deg);GiroZ(dps);X(m);Y(m)"
  //    "0;0.0000;0.00;0.00;0.0000;0.0000"
  //    ...
  //    "--- FIM CSV MAPA ---\nTotal de Pontos: N"
  //
  // 2. Telemetria em tempo real (a cada 100ms durante a corrida):
  //    "0.123,4.567,45.21"  → tempo_s, distancia_m, pitch_deg
  //
  void processIncomingData(String data) {
    // Inicio do GDUMP
    if (data.contains('INICIO CSV MAPA')) {
      _isReceivingMap = true;
      _csvBuffer.clear();
      _trackPoints.clear();
      notifyListeners();
      return;
    }

    // Fim do GDUMP
    if (data.contains('FIM CSV MAPA')) {
      _isReceivingMap = false;
      _parseCsvBuffer();
      notifyListeners();
      return;
    }

    if (_isReceivingMap) {
      // Acumula linhas do CSV; ignora cabecalho e linhas vazias
      final lines = data.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        // Linha de dado: começa com dígito (índice numérico)
        if (trimmed.isNotEmpty && RegExp(r'^\d').hasMatch(trimmed)) {
          _csvBuffer.writeln(trimmed);
        }
      }
      notifyListeners();
      return;
    }

    // Telemetria em tempo real: "tempo_s,distancia_m,pitch_deg"
    _tryParseLiveTelemetry(data);
  }

  // Formato: "0.123,4.567,45.21"  (giroscopiomodule_send_bluetooth_telemetry)
  void _tryParseLiveTelemetry(String data) {
    try {
      final parts = data.trim().split(',');
      if (parts.length < 3) return;
      final timeS = double.tryParse(parts[0]);
      final distM = double.tryParse(parts[1]);
      final pitch = double.tryParse(parts[2]);
      if (timeS == null || distM == null || pitch == null) return;

      _snapshots.add(TelemetrySnapshot(
        timestamp: DateTime.now(),
        distanceM: distM,
        heading: pitch,
        batteryVoltage: 0,
        sensorPosition: 0,
      ));

      if (_snapshots.length > 2000) {
        _snapshots.removeRange(0, _snapshots.length - 2000);
      }
      notifyListeners();
    } catch (_) {}
  }

  void _parseCsvBuffer() {
    final lines = _csvBuffer.toString().split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        try {
          _trackPoints.add(TrackPoint.fromCsv(trimmed));
        } catch (_) {}
      }
    }
    _csvBuffer.clear();
  }

  // ─── Export ───
  String exportCsv() {
    final buffer = StringBuffer();
    buffer.writeln('distance,angle,curvature,x,y,speed');
    for (final point in _trackPoints) {
      buffer.writeln(point.toCsv());
    }
    return buffer.toString();
  }

  // ─── Clear ───
  void clearTrack() {
    _trackPoints.clear();
    notifyListeners();
  }

  void clearSnapshots() {
    _snapshots.clear();
    notifyListeners();
  }

  void clearAll() {
    _trackPoints.clear();
    _snapshots.clear();
    _csvBuffer.clear();
    _isReceivingMap = false;
    notifyListeners();
  }
}
