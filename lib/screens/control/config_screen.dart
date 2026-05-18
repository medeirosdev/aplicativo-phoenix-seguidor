import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ble/ble_protocol.dart';
import '../../core/theme/app_theme.dart';
import '../../models/robot_state.dart';
import '../../providers/ble_provider.dart';
import '../../providers/robot_provider.dart';
import '../../widgets/command_button.dart';
import '../../widgets/status_bar.dart';
import '../control/calibration_screen.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('CONFIGURACAO'), actions: [
        _StepBadge(step: 1, total: 4),
        const SizedBox(width: 12),
      ]),
      body: Column(
        children: [
          const StatusBar(),
          Expanded(
            child: Consumer2<BleProvider, RobotProvider>(
              builder: (context, ble, robot, _) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Modo de corrida
                      _SectionTitle('MODO DE CORRIDA'),
                      const SizedBox(height: 8),
                      _ModeSelector(
                        selected: robot.raceConfig.mode,
                        onSelect: (mode) {
                          robot.setRacingMode(mode);
                          String cmd;
                          switch (mode) {
                            case RacingMode.lineFollower:
                              cmd = BleProtocol.setLineFollower();
                              break;
                            case RacingMode.lineChaser:
                              cmd = BleProtocol.setLineChaser();
                              break;
                            case RacingMode.virtualLine:
                              cmd = BleProtocol.setVirtualLine();
                              break;
                            default:
                              return;
                          }
                          ble.sendCommand(cmd);
                        },
                      ),

                      const SizedBox(height: 28),

                      // Aceleracao
                      _SectionTitle('ACELERACAO'),
                      const SizedBox(height: 8),
                      _ToggleRow(
                        value: robot.raceConfig.accelerationEnabled,
                        onLabel: 'ON',
                        offLabel: 'OFF',
                        onChanged: (enabled) {
                          robot.setAcceleration(enabled);
                          ble.sendCommand(enabled
                              ? BleProtocol.setAccelerationOn()
                              : BleProtocol.setAccelerationOff());
                        },
                      ),

                      const SizedBox(height: 28),

                      // ESC
                      _SectionTitle('ESC / VENTOINHA'),
                      const SizedBox(height: 8),
                      _ToggleRow(
                        value: robot.raceConfig.escEnabled,
                        onLabel: 'ON',
                        offLabel: 'OFF',
                        onChanged: (enabled) {
                          robot.setEsc(enabled);
                          ble.sendCommand(enabled
                              ? BleProtocol.setEscOn()
                              : BleProtocol.setEscOff());
                        },
                      ),

                      const SizedBox(height: 40),

                      // Aplicar e prosseguir
                      CommandButton(
                        label: 'APLICAR E IR PARA CALIBRAÇÃO',
                        subtitle: 'COK → Passo 2',
                        icon: Icons.arrow_forward_rounded,
                        large: true,
                        onPressed: () {
                          ble.sendCommand(BleProtocol.applyConfig());
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const CalibrationScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      // Só aplicar sem navegar
                      CommandButton(
                        label: 'Apenas Aplicar',
                        subtitle: 'COK — sem mudar de tela',
                        icon: Icons.check,
                        outlined: true,
                        onPressed: () {
                          ble.sendCommand(BleProtocol.applyConfig());
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Configuracao aplicada!'),
                              backgroundColor: AppColors.success,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  final int step;
  final int total;
  const _StepBadge({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: Text(
        'Passo $step de $total',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final RacingMode selected;
  final ValueChanged<RacingMode> onSelect;

  const _ModeSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ModeOption(
          label: 'Line Follower',
          subtitle: 'CLF - Kp=1.5, Kd=0.015, V=1.5V',
          icon: Icons.linear_scale,
          selected: selected == RacingMode.lineFollower,
          onTap: () => onSelect(RacingMode.lineFollower),
        ),
        const SizedBox(height: 8),
        _ModeOption(
          label: 'Line Chaser',
          subtitle: 'CLC - Kp=3.4, Kd=0.034, V=4.5V',
          icon: Icons.speed,
          selected: selected == RacingMode.lineChaser,
          onTap: () => onSelect(RacingMode.lineChaser),
        ),
        const SizedBox(height: 8),
        _ModeOption(
          label: 'Virtual Line',
          subtitle: 'CVL - Pure Pursuit, mapa gravado',
          icon: Icons.route,
          selected: selected == RacingMode.virtualLine,
          onTap: () => onSelect(RacingMode.virtualLine),
        ),
      ],
    );
  }
}

class _ModeOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withOpacity(0.15)
          : AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final bool value;
  final String onLabel;
  final String offLabel;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.value,
    required this.onLabel,
    required this.offLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CommandButton(
            label: offLabel,
            icon: Icons.close,
            color: !value ? AppColors.error : AppColors.surfaceLight,
            onPressed: () => onChanged(false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CommandButton(
            label: onLabel,
            icon: Icons.check,
            color: value ? AppColors.success : AppColors.surfaceLight,
            onPressed: () => onChanged(true),
          ),
        ),
      ],
    );
  }
}
