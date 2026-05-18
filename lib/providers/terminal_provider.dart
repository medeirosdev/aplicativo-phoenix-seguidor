import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ble_provider.dart';

enum TerminalMessageType { sent, received }

class TerminalMessage {
  final String text;
  final TerminalMessageType type;
  final DateTime timestamp;

  TerminalMessage({
    required this.text,
    required this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }
}

class TerminalProvider extends ChangeNotifier {
  final List<TerminalMessage> _messages = [];
  bool _paused = false;
  bool _showTimestamp = true;
  bool _autoAddTerminator = true;
  bool _hexMode = false;
  String _filter = '';

  StreamSubscription<String>? _dataSub;

  // ─── Getters ───
  List<TerminalMessage> get messages {
    if (_filter.isEmpty) return List.unmodifiable(_messages);
    return _messages
        .where(
            (m) => m.text.toLowerCase().contains(_filter.toLowerCase()))
        .toList();
  }

  List<TerminalMessage> get allMessages => List.unmodifiable(_messages);
  bool get paused => _paused;
  bool get showTimestamp => _showTimestamp;
  bool get autoAddTerminator => _autoAddTerminator;
  bool get hexMode => _hexMode;
  String get filter => _filter;
  int get messageCount => _messages.length;

  // ─── Conectar ao stream BLE ───
  void listenToBle(BleProvider bleProvider) {
    _dataSub?.cancel();
    _dataSub = bleProvider.receivedDataStream.listen((data) {
      if (!_paused) {
        addReceived(data);
      }
    });
  }

  // ─── Adicionar mensagens ───
  void addSent(String text) {
    _messages.add(TerminalMessage(
      text: text,
      type: TerminalMessageType.sent,
    ));
    _trimMessages();
    notifyListeners();
  }

  void addReceived(String text) {
    _messages.add(TerminalMessage(
      text: text,
      type: TerminalMessageType.received,
    ));
    _trimMessages();
    notifyListeners();
  }

  // Limita a 5000 mensagens para evitar uso excessivo de memoria
  void _trimMessages() {
    if (_messages.length > 5000) {
      _messages.removeRange(0, _messages.length - 5000);
    }
  }

  // ─── Controls ───
  void clear() {
    _messages.clear();
    notifyListeners();
  }

  void togglePause() {
    _paused = !_paused;
    notifyListeners();
  }

  void setShowTimestamp(bool value) {
    _showTimestamp = value;
    notifyListeners();
  }

  void setAutoAddTerminator(bool value) {
    _autoAddTerminator = value;
    notifyListeners();
  }

  void setHexMode(bool value) {
    _hexMode = value;
    notifyListeners();
  }

  void setFilter(String value) {
    _filter = value;
    notifyListeners();
  }

  // ─── Export ───
  String exportLog() {
    final buffer = StringBuffer();
    buffer.writeln('=== Phoenix Terminal Log ===');
    buffer.writeln('Exportado em: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total de mensagens: ${_messages.length}');
    buffer.writeln('===========================\n');

    for (final msg in _messages) {
      final prefix = msg.type == TerminalMessageType.sent ? 'TX' : 'RX';
      buffer.writeln('[${msg.formattedTime}] $prefix: ${msg.text}');
    }
    return buffer.toString();
  }

  @override
  void dispose() {
    _dataSub?.cancel();
    super.dispose();
  }
}
