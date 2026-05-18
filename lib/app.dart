import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/ble_provider.dart';
import 'providers/robot_provider.dart';
import 'providers/terminal_provider.dart';
import 'providers/telemetry_provider.dart';
import 'screens/connection/connection_screen.dart';

class PhoenixApp extends StatelessWidget {
  const PhoenixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BleProvider()),
        ChangeNotifierProvider(create: (_) => RobotProvider()),
        ChangeNotifierProvider(create: (_) => TerminalProvider()),
        ChangeNotifierProvider(create: (_) => TelemetryProvider()),
      ],
      child: const _AppRoot(),
    );
  }
}

/// Widget raiz responsável por conectar o stream BLE ao Terminal e Telemetria.
/// Precisa ser stateful para gerenciar a subscription.
class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  StreamSubscription<String>? _bleSub;

  @override
  void initState() {
    super.initState();
    // Aguarda o primeiro frame para os providers estarem disponíveis
    WidgetsBinding.instance.addPostFrameCallback((_) => _wireBleStream());
  }

  void _wireBleStream() {
    final ble = context.read<BleProvider>();
    final terminal = context.read<TerminalProvider>();
    final telemetry = context.read<TelemetryProvider>();

    // Dados recebidos → terminal + telemetria
    _bleSub?.cancel();
    _bleSub = ble.receivedDataStream.listen((data) {
      terminal.addReceived(data);
      telemetry.processIncomingData(data);
    });

    // Comandos enviados → terminal (TX log)
    ble.onCommandSent = terminal.addSent;
  }

  @override
  void dispose() {
    _bleSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phoenix - Bia PHX-1',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const ConnectionScreen(),
    );
  }
}
