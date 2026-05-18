import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import '../core/ble/ble_service.dart';

class BleProvider extends ChangeNotifier {
  final BleService _bleService = BleService();

  // Estado
  BleConnectionState _connectionState = BleConnectionState.disconnected;
  List<DiscoveredDevice> _scanResults = [];
  String? _connectedDeviceName;
  String? _errorMessage;

  // Subscriptions
  StreamSubscription<BleConnectionState>? _connectionSub;
  StreamSubscription<List<DiscoveredDevice>>? _scanSub;

  BleProvider() {
    _connectionSub = _bleService.connectionStateStream.listen((state) {
      _connectionState = state;
      _connectedDeviceName = _bleService.connectedDeviceName;
      notifyListeners();
    });
    _scanSub = _bleService.scanResultsStream.listen((devices) {
      _scanResults = devices;
      notifyListeners();
    });
  }

  // ─── Getters ───
  BleService get service => _bleService;
  BleConnectionState get connectionState => _connectionState;
  List<DiscoveredDevice> get scanResults => _scanResults;
  String? get connectedDeviceName => _connectedDeviceName;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _connectionState == BleConnectionState.connected;
  bool get isScanning => _connectionState == BleConnectionState.scanning;

  Stream<String> get receivedDataStream => _bleService.receivedDataStream;

  bool get autoReconnect => _bleService.autoReconnect;
  set autoReconnect(bool value) {
    _bleService.autoReconnect = value;
    notifyListeners();
  }

  // ─── Actions ───
  void startScan() {
    _errorMessage = null;
    _bleService.startScan();
  }

  void stopScan() {
    _bleService.stopScan();
  }

  Future<void> connectToDevice(DiscoveredDevice device) async {
    _errorMessage = null;
    try {
      await _bleService.connectToDevice(device);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void disconnect() {
    _bleService.disconnect();
  }

  // Callback opcional para logar comandos enviados no terminal
  void Function(String)? onCommandSent;

  Future<void> sendCommand(String command) async {
    try {
      await _bleService.sendCommand(command);
      onCommandSent?.call(command);
    } catch (e) {
      _errorMessage = 'Erro ao enviar: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    _scanSub?.cancel();
    _bleService.dispose();
    super.dispose();
  }
}
