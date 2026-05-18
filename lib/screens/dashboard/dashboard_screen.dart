import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ble/ble_protocol.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/ble_provider.dart';
import '../../widgets/command_button.dart';
import '../../widgets/status_bar.dart';
import '../connection/connection_screen.dart';
import '../control/config_screen.dart';
import '../control/calibration_screen.dart';
import '../control/race_screen.dart';
import '../control/pid_screen.dart';
import '../virtual_line/virtual_line_screen.dart';
import '../terminal/terminal_screen.dart';
import '../debug/debug_screen.dart';
import '../telemetry/telemetry_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _navigate(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const StatusBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fluxo principal
                  const _SectionLabel('FLUXO DE CORRIDA'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _DashCard(
                          step: 1,
                          icon: Icons.tune,
                          label: 'Configurar',
                          subtitle: 'Modo, accel, ESC',
                          color: AppColors.primary,
                          onTap: () => _navigate(context, const ConfigScreen()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DashCard(
                          step: 2,
                          icon: Icons.sensors,
                          label: 'Calibrar',
                          subtitle: 'Sensores, giro',
                          color: AppColors.info,
                          onTap: () => _navigate(context, const CalibrationScreen()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DashCard(
                          step: 3,
                          icon: Icons.speed,
                          label: 'PID',
                          subtitle: 'Kp, Kd, Vel',
                          color: AppColors.warning,
                          onTap: () => _navigate(context, const PidScreen()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DashCard(
                          step: 4,
                          icon: Icons.flag,
                          label: 'Corrida',
                          subtitle: 'Start / Stop',
                          color: AppColors.success,
                          onTap: () => _navigate(context, const RaceScreen()),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Ferramentas opcionais
                  const _SectionLabel('FERRAMENTAS  (opcional)'),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Em telas estreitas (<340dp) usar grid 2×2,
                      // caso contrario uma linha so de 4
                      if (constraints.maxWidth < 340) {
                        return Column(
                          children: [
                            Row(children: [
                              Expanded(child: _DashCard(
                                icon: Icons.route, label: 'Linha Virtual',
                                subtitle: 'Pure Pursuit',
                                color: Colors.purpleAccent, optional: true,
                                onTap: () => _navigate(context, const VirtualLineScreen()),
                              )),
                              const SizedBox(width: 12),
                              Expanded(child: _DashCard(
                                icon: Icons.analytics, label: 'Telemetria',
                                subtitle: 'Mapa, dados',
                                color: Colors.cyanAccent, optional: true,
                                onTap: () => _navigate(context, const TelemetryScreen()),
                              )),
                            ]),
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(child: _DashCard(
                                icon: Icons.terminal, label: 'Terminal',
                                subtitle: 'Comandos raw',
                                color: AppColors.textSecondary, optional: true,
                                onTap: () => _navigate(context, const TerminalScreen()),
                              )),
                              const SizedBox(width: 12),
                              Expanded(child: _DashCard(
                                icon: Icons.bug_report, label: 'Debug',
                                subtitle: 'Filtros',
                                color: Colors.tealAccent, optional: true,
                                onTap: () => _navigate(context, const DebugScreen()),
                              )),
                            ]),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: _DashCard(
                            icon: Icons.route, label: 'Linha Virtual',
                            subtitle: 'Pure Pursuit',
                            color: Colors.purpleAccent, optional: true,
                            onTap: () => _navigate(context, const VirtualLineScreen()),
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _DashCard(
                            icon: Icons.analytics, label: 'Telemetria',
                            subtitle: 'Mapa, dados',
                            color: Colors.cyanAccent, optional: true,
                            onTap: () => _navigate(context, const TelemetryScreen()),
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _DashCard(
                            icon: Icons.terminal, label: 'Terminal',
                            subtitle: 'Comandos raw',
                            color: AppColors.textSecondary, optional: true,
                            onTap: () => _navigate(context, const TerminalScreen()),
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _DashCard(
                            icon: Icons.bug_report, label: 'Debug',
                            subtitle: 'Filtros',
                            color: Colors.tealAccent, optional: true,
                            onTap: () => _navigate(context, const DebugScreen()),
                          )),
                        ],
                      );
                    },
                  ),

                  const Spacer(),

                  // Botao emergencia
                  EmergencyStopButton(
                    onPressed: () {
                      context.read<BleProvider>().sendCommand(BleProtocol.stopRace());
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: CommandButton(
                          label: 'Desconectar',
                          icon: Icons.bluetooth_disabled,
                          outlined: true,
                          color: AppColors.textSecondary,
                          onPressed: () {
                            context.read<BleProvider>().disconnect();
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const ConnectionScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CommandButton(
                          label: 'Config App',
                          icon: Icons.settings,
                          outlined: true,
                          color: AppColors.textSecondary,
                          onPressed: () => _navigate(context, const SettingsScreen()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _DashCard extends StatelessWidget {
  final int? step;
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool optional;
  final VoidCallback onTap;

  const _DashCard({
    this.step,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    this.optional = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color, size: optional ? 22 : 26),
                  const Spacer(),
                  if (step != null)
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$step',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  if (optional)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'opt',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: optional ? 13 : 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
