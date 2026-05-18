import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/ble/ble_protocol.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/ble_provider.dart';
import '../../providers/robot_provider.dart';
import '../../widgets/status_bar.dart';
import '../control/config_screen.dart';

class RaceScreen extends StatelessWidget {
  const RaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('CORRIDA'),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withOpacity(0.4)),
            ),
            child: const Text(
              'Passo 4 de 4',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const StatusBar(),
          Expanded(
            child: Consumer2<BleProvider, RobotProvider>(
              builder: (context, ble, robot, _) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final btnHeight =
                        (constraints.maxHeight * 0.18).clamp(72.0, 110.0);
                    return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Info do modo
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            Text(
                              robot.raceConfig.mode.label,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Vel: ${robot.pidParams.speed.toStringAsFixed(1)}V  |  '
                              'Kp: ${robot.pidParams.kp.toStringAsFixed(2)}  |  '
                              'Kd: ${robot.pidParams.kd.toStringAsFixed(3)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (robot.raceConfig.accelerationEnabled ||
                                robot.raceConfig.escEnabled)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (robot.raceConfig.accelerationEnabled)
                                      _Badge('ACCEL', AppColors.warning),
                                    if (robot.raceConfig.accelerationEnabled &&
                                        robot.raceConfig.escEnabled)
                                      const SizedBox(width: 8),
                                    if (robot.raceConfig.escEnabled)
                                      _Badge('ESC', AppColors.info),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Botao START
                      SizedBox(
                        width: double.infinity,
                        height: btnHeight,
                        child: Material(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              HapticFeedback.heavyImpact();
                              ble.sendCommand(BleProtocol.startRace());
                            },
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_arrow,
                                      size: btnHeight * 0.42, color: Colors.white),
                                  const SizedBox(width: 12),
                                  Text(
                                    'INICIAR',
                                    style: TextStyle(
                                      fontSize: btnHeight * 0.28,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Botao STOP
                      SizedBox(
                        width: double.infinity,
                        height: btnHeight,
                        child: Material(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              HapticFeedback.heavyImpact();
                              ble.sendCommand(BleProtocol.stopRace());
                            },
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.stop,
                                      size: btnHeight * 0.42, color: Colors.white),
                                  const SizedBox(width: 12),
                                  Text(
                                    'PARAR',
                                    style: TextStyle(
                                      fontSize: btnHeight * 0.28,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Divisor pós-parada
                      const Row(
                        children: [
                          Expanded(child: Divider(color: AppColors.surfaceLight)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'APÓS PARAR',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textHint,
                                  letterSpacing: 1),
                            ),
                          ),
                          Expanded(child: Divider(color: AppColors.surfaceLight)),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Botoes pós-parada (STOP_STATE do robo)
                      // SST → PRE_RACE | COK → CONFIGURATION
                      Row(
                        children: [
                          Expanded(
                            child: _SecondaryButton(
                              label: 'Nova Corrida',
                              subtitle: 'SST → PRE_RACE',
                              icon: Icons.replay,
                              color: AppColors.success,
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                ble.sendCommand(BleProtocol.startRace());
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SecondaryButton(
                              label: 'Nova Config',
                              subtitle: 'COK → CONFIGURATION',
                              icon: Icons.tune,
                              color: AppColors.primary,
                              onTap: () {
                                ble.sendCommand(BleProtocol.applyConfig());
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                      builder: (_) => const ConfigScreen()),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SecondaryButton(
                              label: 'Telemetria',
                              subtitle: 'TP → dados',
                              icon: Icons.analytics,
                              color: AppColors.info,
                              onTap: () =>
                                  ble.sendCommand(BleProtocol.requestTelemetry()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color)),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 9, color: AppColors.textHint)),
            ],
          ),
        ),
      ),
    );
  }
}
