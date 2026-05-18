class PidParams {
  double kp;
  double kd;
  double speed;
  double escPower;
  double accelStep;

  PidParams({
    this.kp = 1.5,
    this.kd = 0.015,
    this.speed = 1.5,
    this.escPower = 0.0,
    this.accelStep = 0.5,
  });

  PidParams.follower()
      : kp = 1.5,
        kd = 0.015,
        speed = 1.5,
        escPower = 0.0,
        accelStep = 0.5;

  PidParams.chaser()
      : kp = 3.4,
        kd = 0.034,
        speed = 4.5,
        escPower = 8.0,
        accelStep = 1.0;

  PidParams copyWith({
    double? kp,
    double? kd,
    double? speed,
    double? escPower,
    double? accelStep,
  }) {
    return PidParams(
      kp: kp ?? this.kp,
      kd: kd ?? this.kd,
      speed: speed ?? this.speed,
      escPower: escPower ?? this.escPower,
      accelStep: accelStep ?? this.accelStep,
    );
  }

  Map<String, dynamic> toJson() => {
        'kp': kp,
        'kd': kd,
        'speed': speed,
        'escPower': escPower,
        'accelStep': accelStep,
      };

  factory PidParams.fromJson(Map<String, dynamic> json) => PidParams(
        kp: (json['kp'] as num?)?.toDouble() ?? 1.5,
        kd: (json['kd'] as num?)?.toDouble() ?? 0.015,
        speed: (json['speed'] as num?)?.toDouble() ?? 1.5,
        escPower: (json['escPower'] as num?)?.toDouble() ?? 0.0,
        accelStep: (json['accelStep'] as num?)?.toDouble() ?? 0.5,
      );
}
