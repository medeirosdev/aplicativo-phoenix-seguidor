import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleConstants {
  static const String deviceName = 'Bia PHX-1';
  static const String manufacturer = 'Phoenix Unicamp';

  static final Uuid serviceUuid =
      Uuid.parse('ab0828b1-198e-4351-b779-901fa0e0371e');
  static final Uuid messageCharacteristicUuid =
      Uuid.parse('4ac8a682-9736-4e5d-932b-e9b31405049c');

  static const int mtuSize = 517;
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration scanTimeout = Duration(seconds: 15);
  static const int maxReconnectAttempts = 3;
}
