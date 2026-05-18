import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'ble_constants.dart';

enum BleConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

class BleService {
  // Na web, FlutterReactiveBle chama Platform.isAndroid no construtor e crasha.
  // Usamos null e guardamos todos os metodos com _ble == null.
  final FlutterReactiveBle? _ble = kIsWeb ? null : FlutterReactiveBle();

  // Estado
  BleConnectionState _connectionState = BleConnectionState.disconnected;
  String? _connectedDeviceId;
  String? _connectedDeviceName;
  int _reconnectAttempts = 0;
  bool _autoReconnect = true;

  // Streams internos
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  StreamSubscription<List<int>>? _notifySubscription;

  // Controllers para expor streams
  final _connectionStateController =
      StreamController<BleConnectionState>.broadcast();
  final _receivedDataController = StreamController<String>.broadcast();
  final _scanResultsController =
      StreamController<List<DiscoveredDevice>>.broadcast();

  // Dispositivos encontrados no scan
  final List<DiscoveredDevice> _discoveredDevices = [];

  // Characteristic principal
  QualifiedCharacteristic? _messageCharacteristic;

  // ─── Getters ───
  BleConnectionState get connectionState => _connectionState;
  String? get connectedDeviceId => _connectedDeviceId;
  String? get connectedDeviceName => _connectedDeviceName;
  bool get isConnected => _connectionState == BleConnectionState.connected;
  bool get autoReconnect => _autoReconnect;

  Stream<BleConnectionState> get connectionStateStream =>
      _connectionStateController.stream;
  Stream<String> get receivedDataStream => _receivedDataController.stream;
  Stream<List<DiscoveredDevice>> get scanResultsStream =>
      _scanResultsController.stream;

  set autoReconnect(bool value) => _autoReconnect = value;

  // ─── Scan ───
  void startScan() {
    if (_ble == null) return;
    _discoveredDevices.clear();
    _updateConnectionState(BleConnectionState.scanning);

    _scanSubscription?.cancel();
    _scanSubscription = _ble!.scanForDevices(
      withServices: [],
      scanMode: ScanMode.lowLatency,
    ).listen(
      (device) {
        // Atualiza ou adiciona dispositivo
        final index = _discoveredDevices
            .indexWhere((d) => d.id == device.id);
        if (index >= 0) {
          _discoveredDevices[index] = device;
        } else if (device.name.isNotEmpty) {
          _discoveredDevices.add(device);
        }

        // Ordena: Bia PHX-1 primeiro, depois por RSSI
        _discoveredDevices.sort((a, b) {
          if (a.name == BleConstants.deviceName) return -1;
          if (b.name == BleConstants.deviceName) return 1;
          return b.rssi.compareTo(a.rssi);
        });

        _scanResultsController.add(List.from(_discoveredDevices));
      },
      onError: (error) {
        _updateConnectionState(BleConnectionState.error);
      },
    );

    // Auto-stop scan apos timeout
    Future.delayed(BleConstants.scanTimeout, () {
      if (_connectionState == BleConnectionState.scanning) {
        stopScan();
      }
    });
  }

  void stopScan() {
    _scanSubscription?.cancel();
    _scanSubscription = null;
    if (_connectionState == BleConnectionState.scanning) {
      _updateConnectionState(BleConnectionState.disconnected);
    }
  }

  // ─── Connect ───
  Future<void> connectToDevice(DiscoveredDevice device) async {
    if (_ble == null) return;
    stopScan();
    _updateConnectionState(BleConnectionState.connecting);
    _connectedDeviceId = device.id;
    _connectedDeviceName = device.name;
    _reconnectAttempts = 0;

    _connectionSubscription?.cancel();
    _connectionSubscription = _ble!
        .connectToDevice(
      id: device.id,
      connectionTimeout: BleConstants.connectionTimeout,
    )
        .listen(
      (update) async {
        switch (update.connectionState) {
          case DeviceConnectionState.connected:
            _reconnectAttempts = 0;
            await _onConnected(device.id);
            break;
          case DeviceConnectionState.disconnected:
            _onDisconnected();
            break;
          case DeviceConnectionState.connecting:
            _updateConnectionState(BleConnectionState.connecting);
            break;
          case DeviceConnectionState.disconnecting:
            break;
        }
      },
      onError: (error) {
        _updateConnectionState(BleConnectionState.error);
        _tryReconnect();
      },
    );
  }

  Future<void> _onConnected(String deviceId) async {
    // Configura characteristic
    _messageCharacteristic = QualifiedCharacteristic(
      serviceId: BleConstants.serviceUuid,
      characteristicId: BleConstants.messageCharacteristicUuid,
      deviceId: deviceId,
    );

    // Negociar MTU
    try {
      await _ble!.requestMtu(deviceId: deviceId, mtu: BleConstants.mtuSize);
    } catch (_) {
      // Alguns devices nao suportam MTU custom - ok
    }

    // Inscrever em notificacoes
    _notifySubscription?.cancel();
    _notifySubscription = _ble!
        .subscribeToCharacteristic(_messageCharacteristic!)
        .listen(
      (data) {
        if (data.isNotEmpty) {
          final message = utf8.decode(data);
          _receivedDataController.add(message);
        }
      },
      onError: (error) {
        // Erro de notificacao - logar mas nao desconectar
      },
    );

    _updateConnectionState(BleConnectionState.connected);
  }

  void _onDisconnected() {
    _notifySubscription?.cancel();
    _notifySubscription = null;
    _messageCharacteristic = null;
    _updateConnectionState(BleConnectionState.disconnected);

    if (_autoReconnect) {
      _tryReconnect();
    }
  }

  void _tryReconnect() {
    if (_connectedDeviceId == null) return;
    if (_reconnectAttempts >= BleConstants.maxReconnectAttempts) return;
    if (_connectionState == BleConnectionState.connecting) return;

    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);

    Future.delayed(delay, () {
      if (_connectionState == BleConnectionState.disconnected &&
          _connectedDeviceId != null) {
        _updateConnectionState(BleConnectionState.connecting);
        _connectionSubscription?.cancel();
        _connectionSubscription = _ble!
            .connectToDevice(
          id: _connectedDeviceId!,
          connectionTimeout: BleConstants.connectionTimeout,
        )
            .listen(
          (update) async {
            if (update.connectionState == DeviceConnectionState.connected) {
              await _onConnected(_connectedDeviceId!);
            } else if (update.connectionState ==
                DeviceConnectionState.disconnected) {
              _onDisconnected();
            }
          },
          onError: (_) => _tryReconnect(),
        );
      }
    });
  }

  // ─── Disconnect ───
  void disconnect() {
    _autoReconnect = false;
    _connectionSubscription?.cancel();
    _notifySubscription?.cancel();
    _connectionSubscription = null;
    _notifySubscription = null;
    _messageCharacteristic = null;
    _connectedDeviceId = null;
    _connectedDeviceName = null;
    _updateConnectionState(BleConnectionState.disconnected);
  }

  // ─── Write ───
  Future<void> sendCommand(String command) async {
    if (_ble == null || _messageCharacteristic == null || !isConnected) return;

    final data = utf8.encode(command);
    await _ble!.writeCharacteristicWithResponse(
      _messageCharacteristic!,
      value: data,
    );
  }

  // ─── Read ───
  Future<String?> readCharacteristic() async {
    if (_ble == null || _messageCharacteristic == null || !isConnected) return null;

    final data =
        await _ble!.readCharacteristic(_messageCharacteristic!);
    return utf8.decode(data);
  }

  // ─── Helpers ───
  void _updateConnectionState(BleConnectionState state) {
    _connectionState = state;
    _connectionStateController.add(state);
  }

  // ─── Dispose ───
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _notifySubscription?.cancel();
    _connectionStateController.close();
    _receivedDataController.close();
    _scanResultsController.close();
  }
}
