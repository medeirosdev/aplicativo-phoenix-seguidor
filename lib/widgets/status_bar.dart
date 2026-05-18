import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/ble/ble_service.dart';
import '../core/theme/app_theme.dart';
import '../providers/ble_provider.dart';
import '../providers/robot_provider.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<BleProvider, RobotProvider>(
      builder: (context, ble, robot, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.surfaceLight, width: 1),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                // Indicador de conexao
                _ConnectionBadge(state: ble.connectionState),
                const SizedBox(width: 12),
                // Nome do dispositivo
                Expanded(
                  child: Text(
                    ble.connectedDeviceName ?? 'Desconectado',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Bateria
                if (robot.batteryVoltage > 0) ...[
                  _BatteryIndicator(
                    voltage: robot.batteryVoltage,
                    status: robot.batteryStatus,
                  ),
                  const SizedBox(width: 12),
                ],
                // Modo atual
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    robot.raceConfig.mode.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  final BleConnectionState state;
  const _ConnectionBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (state) {
      case BleConnectionState.connected:
        color = AppColors.bleConnected;
        icon = Icons.bluetooth_connected;
        break;
      case BleConnectionState.scanning:
        color = AppColors.bleScanning;
        icon = Icons.bluetooth_searching;
        break;
      case BleConnectionState.connecting:
        color = AppColors.warning;
        icon = Icons.bluetooth;
        break;
      case BleConnectionState.error:
        color = AppColors.bleError;
        icon = Icons.bluetooth_disabled;
        break;
      case BleConnectionState.disconnected:
        color = AppColors.bleDisconnected;
        icon = Icons.bluetooth_disabled;
        break;
    }

    return Icon(icon, color: color, size: 20);
  }
}

class _BatteryIndicator extends StatelessWidget {
  final double voltage;
  final dynamic status;
  const _BatteryIndicator({required this.voltage, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    if (voltage >= 12.0) {
      color = AppColors.success;
      icon = Icons.battery_full;
    } else if (voltage >= 11.2) {
      color = AppColors.warning;
      icon = Icons.battery_3_bar;
    } else if (voltage > 3.0) {
      color = AppColors.error;
      icon = Icons.battery_1_bar;
    } else {
      color = AppColors.textSecondary;
      icon = Icons.usb;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(
          '${voltage.toStringAsFixed(1)}V',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
