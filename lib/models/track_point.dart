class TrackPoint {
  final double distanceM;
  final double angleYaw;
  final double curvatureDps;
  final double x;
  final double y;
  final double targetSpeed;

  const TrackPoint({
    required this.distanceM,
    required this.angleYaw,
    required this.curvatureDps,
    required this.x,
    required this.y,
    this.targetSpeed = 0.0,
  });

  /// Parse uma linha do GDUMP do firmware.
  /// Formato: Index;Dist(m);Yaw(deg);GiroZ(dps);X(m);Y(m)
  /// Exemplo:  0;0.0200;12.34;5.67;0.0199;0.0001
  factory TrackPoint.fromCsv(String line) {
    // Suporta separador ; (firmware) ou , (exportacao interna)
    final sep = line.contains(';') ? ';' : ',';
    final parts = line.split(sep);

    if (sep == ';') {
      // Formato firmware: Index;Dist;Yaw;GiroZ;X;Y
      if (parts.length < 6) throw FormatException('Linha incompleta: $line');
      return TrackPoint(
        distanceM: double.tryParse(parts[1]) ?? 0,
        angleYaw: double.tryParse(parts[2]) ?? 0,
        curvatureDps: double.tryParse(parts[3]) ?? 0,
        x: double.tryParse(parts[4]) ?? 0,
        y: double.tryParse(parts[5]) ?? 0,
      );
    } else {
      // Formato interno exportacao: distance,angle,curvature,x,y[,speed]
      if (parts.length < 5) throw FormatException('Linha incompleta: $line');
      return TrackPoint(
        distanceM: double.tryParse(parts[0]) ?? 0,
        angleYaw: double.tryParse(parts[1]) ?? 0,
        curvatureDps: double.tryParse(parts[2]) ?? 0,
        x: double.tryParse(parts[3]) ?? 0,
        y: double.tryParse(parts[4]) ?? 0,
        targetSpeed: parts.length > 5 ? (double.tryParse(parts[5]) ?? 0) : 0,
      );
    }
  }

  String toCsv() =>
      '${distanceM.toStringAsFixed(4)},${angleYaw.toStringAsFixed(2)},${curvatureDps.toStringAsFixed(2)},${x.toStringAsFixed(4)},${y.toStringAsFixed(4)},${targetSpeed.toStringAsFixed(2)}';
}
