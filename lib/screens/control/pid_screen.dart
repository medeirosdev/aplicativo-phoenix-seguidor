import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ble/ble_protocol.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/ble_provider.dart';
import '../../providers/robot_provider.dart';
import '../../widgets/command_button.dart';
import '../../widgets/pid_slider.dart';
import '../../widgets/status_bar.dart';
import '../control/race_screen.dart';

class PidScreen extends StatelessWidget {
  const PidScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AJUSTE PID'),
        actions: [
          _StepBadge(step: 3, total: 4),
          const SizedBox(width: 12),
        ],
      ),
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
                      // Info opcional
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.warning.withOpacity(0.25)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.warning, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Opcional — os presets ja vem configurados. '
                                'Ajuste somente se necessario.',
                                style: TextStyle(fontSize: 11, color: AppColors.warning),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Presets
                      const Text(
                        'PRESETS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: CommandButton(
                              label: 'Follower',
                              subtitle: 'Kp=1.5 Kd=0.015',
                              outlined: true,
                              onPressed: () => robot.loadPreset('follower'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CommandButton(
                              label: 'Chaser',
                              subtitle: 'Kp=3.4 Kd=0.034',
                              outlined: true,
                              onPressed: () => robot.loadPreset('chaser'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Sliders
                      const Text(
                        'PARAMETROS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      PidSlider(
                        label: 'Kp (Proporcional)',
                        value: robot.pidParams.kp,
                        min: 0.0,
                        max: 10.0,
                        decimals: 3,
                        onChanged: (v) => robot.setKp(v),
                        onChangeEnd: (v) => ble.sendCommand(BleProtocol.setKp(v)),
                      ),
                      PidSlider(
                        label: 'Kd (Derivativo)',
                        value: robot.pidParams.kd,
                        min: 0.0,
                        max: 0.5,
                        decimals: 4,
                        onChanged: (v) => robot.setKd(v),
                        onChangeEnd: (v) => ble.sendCommand(BleProtocol.setKd(v)),
                      ),
                      PidSlider(
                        label: 'Velocidade Base',
                        unit: 'V',
                        value: robot.pidParams.speed,
                        min: 0.0,
                        max: 12.0,
                        decimals: 2,
                        onChanged: (v) => robot.setSpeed(v),
                        onChangeEnd: (v) => ble.sendCommand(BleProtocol.setSpeed(v)),
                      ),
                      PidSlider(
                        label: 'ESC Power',
                        unit: 'V',
                        value: robot.pidParams.escPower,
                        min: 0.0,
                        max: 12.0,
                        decimals: 1,
                        onChanged: (v) => robot.setEscPower(v),
                        onChangeEnd: (v) => ble.sendCommand(BleProtocol.setEscPower(v)),
                      ),
                      PidSlider(
                        label: 'Accel Step',
                        value: robot.pidParams.accelStep,
                        min: 0.0,
                        max: 3.0,
                        decimals: 2,
                        onChanged: (v) => robot.setAccelStep(v),
                        onChangeEnd: (v) => ble.sendCommand(BleProtocol.setAccelStep(v)),
                      ),

                      const SizedBox(height: 16),

                      // Consultar / Enviar
                      Row(
                        children: [
                          Expanded(
                            child: CommandButton(
                              label: 'Consultar',
                              subtitle: 'PC',
                              icon: Icons.download,
                              outlined: true,
                              onPressed: () => ble.sendCommand(BleProtocol.consultPid()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CommandButton(
                              label: 'Enviar Todos',
                              icon: Icons.upload,
                              onPressed: () {
                                final p = robot.pidParams;
                                ble.sendCommand(BleProtocol.setKp(p.kp));
                                ble.sendCommand(BleProtocol.setKd(p.kd));
                                ble.sendCommand(BleProtocol.setSpeed(p.speed));
                                ble.sendCommand(BleProtocol.setEscPower(p.escPower));
                                ble.sendCommand(BleProtocol.setAccelStep(p.accelStep));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Todos os parametros enviados!'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Prosseguir
                      CommandButton(
                        label: 'IR PARA CORRIDA',
                        subtitle: 'Passo 4 → Start / Stop',
                        icon: Icons.arrow_forward_rounded,
                        large: true,
                        color: AppColors.success,
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const RaceScreen()),
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
        color: AppColors.warning.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
      ),
      child: Text(
        'Passo $step de $total',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.warning,
        ),
      ),
    );
  }
}
