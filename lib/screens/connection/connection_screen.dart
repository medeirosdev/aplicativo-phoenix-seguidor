import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/ble/ble_constants.dart';
import '../../core/ble/ble_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/ble_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../demo/demo_screen.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissionsAndScan();
    });
  }

  Future<void> _requestPermissionsAndScan() async {
    final permissions = [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ];

    final statuses = await permissions.request();

    final allGranted = statuses.values.every(
      (s) => s == PermissionStatus.granted || s == PermissionStatus.limited,
    );

    if (!mounted) return;

    if (allGranted) {
      context.read<BleProvider>().startScan();
    } else {
      final denied = statuses.entries
          .where((e) => e.value.isDenied || e.value.isPermanentlyDenied)
          .map((e) => e.key.toString().split('.').last)
          .join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Permissoes negadas: $denied\nVa em Configuracoes > Apps > Phoenix > Permissoes'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Configuracoes',
            textColor: Colors.white,
            onPressed: openAppSettings,
          ),
        ),
      );
    }
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo e titulo
              const Icon(
                Icons.precision_manufacturing_rounded,
                color: AppColors.primary,
                size: 80,
              ),
              const SizedBox(height: 16),
              const Text(
                'PHOENIX',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: 6,
                ),
              ),
              const Text(
                'Controle da Bia',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              // Botao DEBUG / Preview
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DemoScreen()),
                  );
                },
                icon: const Icon(Icons.preview, size: 18, color: AppColors.warning),
                label: const Text(
                  'DEMO — ver design sem conectar',
                  style: TextStyle(color: AppColors.warning, fontSize: 13),
                ),
              ),
              const SizedBox(height: 24),
              // Botao scan / status
              Consumer<BleProvider>(
                builder: (context, ble, _) {
                  return _ScanButton(
                    state: ble.connectionState,
                    onPressed: () {
                      if (ble.isScanning) {
                        ble.stopScan();
                      } else {
                        _requestPermissionsAndScan();
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              // Lista de dispositivos
              Expanded(
                child: Consumer<BleProvider>(
                  builder: (context, ble, _) {
                    // Se conectou, navegar
                    if (ble.isConnected) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _navigateToDashboard();
                      });
                    }

                    if (ble.scanResults.isEmpty && !ble.isScanning) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bluetooth_searching,
                                color: AppColors.textHint, size: 48),
                            SizedBox(height: 12),
                            Text(
                              'Toque em Escanear para\nencontrar dispositivos',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }

                    if (ble.scanResults.isEmpty && ble.isScanning) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: AppColors.primary),
                            SizedBox(height: 16),
                            Text(
                              'Procurando dispositivos BLE...',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: ble.scanResults.length,
                      itemBuilder: (context, index) {
                        final device = ble.scanResults[index];
                        final isBia =
                            device.name == BleConstants.deviceName;

                        return _DeviceCard(
                          device: device,
                          isBia: isBia,
                          isConnecting: ble.connectionState ==
                              BleConnectionState.connecting,
                          onConnect: () => ble.connectToDevice(device),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final BleConnectionState state;
  final VoidCallback onPressed;

  const _ScanButton({required this.state, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isScanning = state == BleConnectionState.scanning;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isScanning
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.bluetooth_searching),
        label: Text(isScanning ? 'Escaneando...' : 'Escanear'),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isScanning ? AppColors.surfaceLight : AppColors.primary,
        ),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final DiscoveredDevice device;
  final bool isBia;
  final bool isConnecting;
  final VoidCallback onConnect;

  const _DeviceCard({
    required this.device,
    required this.isBia,
    required this.isConnecting,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isBia ? AppColors.primary.withOpacity(0.1) : AppColors.card,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Icon(
          isBia ? Icons.precision_manufacturing : Icons.bluetooth,
          color: isBia ? AppColors.primary : AppColors.textSecondary,
          size: 28,
        ),
        title: Text(
          device.name.isEmpty ? 'Desconhecido' : device.name,
          style: TextStyle(
            fontWeight: isBia ? FontWeight.w700 : FontWeight.w500,
            color: isBia ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          '${device.id}  |  RSSI: ${device.rssi} dBm',
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: isConnecting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : ElevatedButton(
                onPressed: onConnect,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor:
                      isBia ? AppColors.primary : AppColors.surfaceLight,
                ),
                child: Text(isBia ? 'Conectar' : 'Conectar'),
              ),
      ),
    );
  }
}
