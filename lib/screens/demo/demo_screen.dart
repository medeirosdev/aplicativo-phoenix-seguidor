import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/pid_params.dart';
import '../../models/robot_state.dart';
import '../../models/track_point.dart';
import '../../providers/robot_provider.dart';
import '../../providers/terminal_provider.dart';
import '../../widgets/command_button.dart';
import '../../widgets/pid_slider.dart';
import '../../widgets/status_bar.dart';
import '../../widgets/track_map_painter.dart';

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  int _selectedTab = 0;

  final List<_DemoTab> _tabs = const [
    _DemoTab(icon: Icons.dashboard, label: 'Dashboard'),
    _DemoTab(icon: Icons.tune, label: 'Config', step: 1),
    _DemoTab(icon: Icons.sensors, label: 'Calibrar', step: 2),
    _DemoTab(icon: Icons.speed, label: 'PID', step: 3),
    _DemoTab(icon: Icons.flag, label: 'Corrida', step: 4),
    _DemoTab(icon: Icons.terminal, label: 'Terminal'),
    _DemoTab(icon: Icons.analytics, label: 'Telemetria'),
  ];

  @override
  void initState() {
    super.initState();
    _injectDemoData();
  }

  void _injectDemoData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final robot = context.read<RobotProvider>();
      robot.setRacingMode(RacingMode.lineFollower);
      robot.updateBattery(11.82);

      final terminal = context.read<TerminalProvider>();
      terminal.addReceived('Bia PHX-1 conectada!');
      terminal.addReceived('Bluetooth iniciado - MTU: 517');
      // Passo 1: Configurar
      terminal.addSent('CLF\r');
      terminal.addReceived('Modo: Line Follower');
      terminal.addSent('CA1\r');
      terminal.addReceived('Aceleracao: ON');
      terminal.addSent('COK\r');
      terminal.addReceived('Config aplicada!');
      // Passo 2: Calibrar giroscopio primeiro
      terminal.addSent('GC\r');
      terminal.addReceived('Calibrando giroscopio...');
      terminal.addReceived('Gyro bias: -0.67 dps — EXCELENTE');
      // Calibrar sensores
      terminal.addSent('KM0\r');
      terminal.addReceived('Modo: calibracao manual');
      terminal.addSent('KOK\r');
      terminal.addReceived('Calibracao iniciada...');
      terminal.addReceived('Sensor[0]: min=120 max=3820');
      terminal.addReceived('Sensor[1]: min=115 max=3750');
      terminal.addReceived('Sensor[2]: min=108 max=3800');
      terminal.addReceived('Calibracao concluida!');
      // Passo 3: PID
      terminal.addSent('PP,1.500\r');
      terminal.addReceived('Kp: 1.500');
      terminal.addSent('PD,0.0150\r');
      terminal.addReceived('Kd: 0.0150');
      terminal.addSent('PV,1.50\r');
      terminal.addReceived('Vel: 1.50V');
      // Passo 4: Corrida
      terminal.addSent('SST\r');
      terminal.addReceived('CORRIDA INICIADA');
      // Telemetria em formato correto: tempo_s,distancia_m,pitch_deg
      terminal.addReceived('0.000,0.000,0.00');
      terminal.addReceived('0.125,0.123,5.60');
      terminal.addReceived('0.250,0.247,12.30');
      terminal.addReceived('0.375,0.391,8.10');
      terminal.addReceived('0.500,0.534,3.20');
      terminal.addSent('SSP\r');
      terminal.addReceived('PARADA DE EMERGENCIA');
    });
  }

  List<TrackPoint> _generateDemoTrack() {
    final points = <TrackPoint>[];
    const steps = 120;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps * 2 * 3.14159265;
      final px = 0.6 * (1.2 * (1 - (i / steps) * 0.1)) *
          (i / steps < 0.5
              ? (i / steps) * 2.4 - 0.2
              : 2.0 - (i / steps) * 2.4);
      final py = 0.4 * (i / steps < 0.25
          ? (i / steps) * 4
          : i / steps < 0.75
              ? 1.0
              : (1.0 - (i / steps)) * 4);
      final curv = 50.0 * (i % 30 < 5 ? 8.0 : i % 30 < 10 ? 4.0 : 1.0);
      points.add(TrackPoint(
        distanceM: i * 0.35,
        angleYaw: t * 57.3,
        curvatureDps: curv,
        x: px,
        y: py,
        targetSpeed: 1.5 + (curv > 200 ? 0.0 : 1.0),
      ));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.warning, width: 1),
              ),
              child: const Text(
                'DEMO',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Preview do App'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Sair',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
      body: Column(
        children: [
          _DemoStatusBar(),
          Expanded(child: _buildTab()),
          _DemoTabBar(
            tabs: _tabs,
            selected: _selectedTab,
            onTap: (i) => setState(() => _selectedTab = i),
          ),
        ],
      ),
    );
  }

  Widget _buildTab() {
    final track = _generateDemoTrack();
    switch (_selectedTab) {
      case 0:
        return _DemoDashboard(
            onNavigate: (i) => setState(() => _selectedTab = i));
      case 1:
        return _DemoConfig(
            onNext: () => setState(() => _selectedTab = 2));
      case 2:
        return _DemoCalibration(
            onNext: () => setState(() => _selectedTab = 3));
      case 3:
        return _DemoPid(
            onNext: () => setState(() => _selectedTab = 4));
      case 4:
        return _DemoRace();
      case 5:
        return _DemoTerminal();
      case 6:
        return _DemoTelemetry(track: track);
      default:
        return const SizedBox();
    }
  }
}

// ─── Status bar demo ───
class _DemoStatusBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.surfaceLight)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bluetooth_connected,
              color: AppColors.bleConnected, size: 20),
          const SizedBox(width: 8),
          const Text('Bia PHX-1',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const Spacer(),
          const Icon(Icons.battery_3_bar,
              color: AppColors.warning, size: 18),
          const SizedBox(width: 4),
          const Text('11.8V',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Line Follower',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// ─── Tab bar demo (scrollável) ───
class _DemoTab {
  final IconData icon;
  final String label;
  final int? step;
  const _DemoTab({required this.icon, required this.label, this.step});
}

class _DemoTabBar extends StatelessWidget {
  final List<_DemoTab> tabs;
  final int selected;
  final ValueChanged<int> onTap;
  const _DemoTabBar(
      {required this.tabs, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: List.generate(tabs.length, (i) {
            final active = i == selected;
            final tab = tabs[i];
            return GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(tab.icon,
                            size: 22,
                            color: active
                                ? AppColors.primary
                                : AppColors.textSecondary),
                        if (tab.step != null)
                          Positioned(
                            top: -4,
                            right: -6,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${tab.step}',
                                  style: const TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: active
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight:
                            active ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─── Dashboard demo ───
class _DemoDashboard extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const _DemoDashboard({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fluxo principal numerado
          const _DemoSectionTitle('FLUXO DE CORRIDA'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: _DemoFlowCard(
                step: 1,
                icon: Icons.tune,
                label: 'Configurar',
                subtitle: 'Modo, accel, ESC',
                color: AppColors.primary,
                onTap: () => onNavigate(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DemoFlowCard(
                step: 2,
                icon: Icons.sensors,
                label: 'Calibrar',
                subtitle: 'GC → sensores',
                color: AppColors.info,
                onTap: () => onNavigate(2),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _DemoFlowCard(
                step: 3,
                icon: Icons.speed,
                label: 'PID',
                subtitle: 'Kp, Kd, Vel',
                color: AppColors.warning,
                onTap: () => onNavigate(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DemoFlowCard(
                step: 4,
                icon: Icons.flag,
                label: 'Corrida',
                subtitle: 'Start / Stop',
                color: AppColors.success,
                onTap: () => onNavigate(4),
              ),
            ),
          ]),

          const SizedBox(height: 20),

          // Ferramentas opcionais
          const _DemoSectionTitle('FERRAMENTAS  (opcional)'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: _DemoOptCard(
                icon: Icons.route,
                label: 'Linha Virtual',
                color: Colors.purpleAccent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DemoOptCard(
                icon: Icons.analytics,
                label: 'Telemetria',
                color: Colors.cyanAccent,
                onTap: () => onNavigate(6),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DemoOptCard(
                icon: Icons.terminal,
                label: 'Terminal',
                color: AppColors.textSecondary,
                onTap: () => onNavigate(5),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DemoOptCard(
                icon: Icons.bug_report,
                label: 'Debug',
                color: Colors.tealAccent,
              ),
            ),
          ]),

          const SizedBox(height: 16),

          // Parada de emergência
          EmergencyStopButton(onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('SSP enviado → Parada de emergencia!'),
                backgroundColor: AppColors.error,
                duration: Duration(seconds: 2),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DemoFlowCard extends StatelessWidget {
  final int step;
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DemoFlowCard({
    required this.step,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
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
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color, size: 26),
                  const Spacer(),
                  Container(
                    width: 22,
                    height: 22,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        '$step',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoOptCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _DemoOptCard({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: color, size: 22),
                  Positioned(
                    top: -3,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 3, vertical: 1),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('opt',
                          style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.w700,
                              color: color)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Config demo ───
class _DemoConfig extends StatefulWidget {
  final VoidCallback onNext;
  const _DemoConfig({required this.onNext});

  @override
  State<_DemoConfig> createState() => _DemoConfigState();
}

class _DemoConfigState extends State<_DemoConfig> {
  int _mode = 0;
  bool _accel = false;
  bool _esc = false;

  @override
  Widget build(BuildContext context) {
    final modes = [
      ('Line Follower', 'CLF — Kp=1.5, V=1.5V', Icons.linear_scale),
      ('Line Chaser', 'CLC — Kp=3.4, V=4.5V', Icons.speed),
      ('Virtual Line', 'CVL — Pure Pursuit', Icons.route),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepBadge('Passo 1 de 4 — Configuracao', AppColors.primary),
          const SizedBox(height: 12),
          const _DemoSectionTitle('MODO DE CORRIDA'),
          const SizedBox(height: 8),
          ...List.generate(
            modes.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DemoModeOption(
                label: modes[i].$1,
                subtitle: modes[i].$2,
                icon: modes[i].$3,
                selected: _mode == i,
                onTap: () => setState(() => _mode = i),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _DemoSectionTitle('ACELERACAO'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: CommandButton(
                label: 'OFF',
                icon: Icons.close,
                color: !_accel ? AppColors.error : AppColors.surfaceLight,
                onPressed: () => setState(() => _accel = false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CommandButton(
                label: 'ON',
                icon: Icons.check,
                color: _accel ? AppColors.success : AppColors.surfaceLight,
                onPressed: () => setState(() => _accel = true),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          const _DemoSectionTitle('ESC / VENTOINHA'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: CommandButton(
                label: 'OFF',
                icon: Icons.close,
                color: !_esc ? AppColors.error : AppColors.surfaceLight,
                onPressed: () => setState(() => _esc = false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CommandButton(
                label: 'ON',
                icon: Icons.check,
                color: _esc ? AppColors.success : AppColors.surfaceLight,
                onPressed: () => setState(() => _esc = true),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          CommandButton(
            label: 'APLICAR E IR PARA CALIBRAÇÃO',
            subtitle: 'COK → Passo 2',
            icon: Icons.arrow_forward,
            large: true,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Enviado: ${['CLF', 'CLC', 'CVL'][_mode]} → COK'),
                  backgroundColor: AppColors.success,
                  duration: const Duration(seconds: 2),
                ),
              );
              widget.onNext();
            },
          ),
        ],
      ),
    );
  }
}

class _DemoModeOption extends StatelessWidget {
  final String label, subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _DemoModeOption(
      {required this.label,
      required this.subtitle,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary.withOpacity(0.15) : AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textPrimary)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary)),
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

// ─── Calibração demo ───
class _DemoCalibration extends StatefulWidget {
  final VoidCallback onNext;
  const _DemoCalibration({required this.onNext});

  @override
  State<_DemoCalibration> createState() => _DemoCalibrationState();
}

class _DemoCalibrationState extends State<_DemoCalibration> {
  bool _gyroCalibrated = false;
  int _sensorType = 0; // 0=KM0, 1=KME, 2=KEE
  bool _calibrating = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepBadge('Passo 2 de 4 — Calibracao', AppColors.info),
          const SizedBox(height: 12),

          // Etapa A: Giroscopio
          _DemoStepRow(
            letter: 'A',
            label: 'Calibrar Giroscópio',
            color: AppColors.info,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.info.withOpacity(0.25)),
            ),
            child: const Text(
              'Deixe o robô completamente parado. '
              'O giroscópio leva ~10 s para calibrar o bias.',
              style:
                  TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          CommandButton(
            label: _gyroCalibrated ? 'Giroscópio OK ✓' : 'Calibrar Giroscópio',
            subtitle: 'GC — robot parado ~10s',
            icon:
                _gyroCalibrated ? Icons.check_circle : Icons.rotate_right,
            color: _gyroCalibrated ? AppColors.success : AppColors.info,
            outlined: !_gyroCalibrated,
            onPressed: () {
              setState(() => _gyroCalibrated = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'GC enviado — aguarde ~10s sem mover o robô'),
                  backgroundColor: AppColors.info,
                  duration: Duration(seconds: 5),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Etapa B: Tipo de calibração
          _DemoStepRow(
            letter: 'B',
            label: 'Selecionar Tipo',
            color: AppColors.warning,
          ),
          const SizedBox(height: 8),
          ...([
            ('Manual (KM0)', 'Mova o robô sobre a linha', Icons.pan_tool),
            ('Manual + EEPROM (KME)', 'Manual e salva na memória', Icons.save),
            ('Da EEPROM (KEE)', 'Usa calibração salva anteriormente',
                Icons.storage),
          ].indexed.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DemoModeOption(
                label: entry.$2.$1,
                subtitle: entry.$2.$2,
                icon: entry.$2.$3,
                selected: _sensorType == entry.$1,
                onTap: () => setState(() => _sensorType = entry.$1),
              ),
            ),
          )),

          const SizedBox(height: 16),

          // Etapa C: Executar
          _DemoStepRow(
            letter: 'C',
            label: 'Executar Calibração',
            color: AppColors.success,
          ),
          const SizedBox(height: 4),
          if (_sensorType == 0)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.warning.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppColors.warning, size: 14),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Após KOK, mova lentamente o robô sobre toda a linha.',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.success.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: AppColors.success, size: 14),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Não precisa mover o robô — dados da EEPROM são carregados automaticamente.',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          CommandButton(
            label: 'Executar Calibração',
            subtitle: 'KOK — inicia calibração',
            icon: Icons.play_arrow,
            large: true,
            onPressed: () {
              if (!_gyroCalibrated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Calibre o giroscópio primeiro! (Etapa A)'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              setState(() => _calibrating = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('KOK enviado — calibrando sensores...'),
                  backgroundColor: AppColors.success,
                  duration: Duration(seconds: 2),
                ),
              );
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) widget.onNext();
              });
            },
          ),

          const SizedBox(height: 16),

          // Prosseguir para PID
          CommandButton(
            label: 'IR PARA PID',
            subtitle: 'Passo 3',
            icon: Icons.arrow_forward,
            outlined: true,
            color: AppColors.warning,
            onPressed: widget.onNext,
          ),
        ],
      ),
    );
  }
}

class _DemoStepRow extends StatelessWidget {
  final String letter;
  final String label;
  final Color color;

  const _DemoStepRow(
      {required this.letter, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(
            child: Text(
              letter,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.black),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5),
        ),
      ],
    );
  }
}

// ─── PID demo ───
class _DemoPid extends StatefulWidget {
  final VoidCallback onNext;
  const _DemoPid({required this.onNext});

  @override
  State<_DemoPid> createState() => _DemoPidState();
}

class _DemoPidState extends State<_DemoPid> {
  final _pid = PidParams.follower();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepBadge('Passo 3 de 4 — PID', AppColors.warning),
          const SizedBox(height: 12),
          const _DemoSectionTitle('PRESETS'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: CommandButton(
                label: 'Follower',
                subtitle: 'Kp=1.5 Kd=0.015',
                outlined: true,
                onPressed: () => setState(() {
                  _pid.kp = 1.5;
                  _pid.kd = 0.015;
                  _pid.speed = 1.5;
                  _pid.escPower = 0;
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CommandButton(
                label: 'Chaser',
                subtitle: 'Kp=3.4 Kd=0.034',
                outlined: true,
                onPressed: () => setState(() {
                  _pid.kp = 3.4;
                  _pid.kd = 0.034;
                  _pid.speed = 4.5;
                  _pid.escPower = 8.0;
                }),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          const _DemoSectionTitle('PARAMETROS'),
          const SizedBox(height: 8),
          PidSlider(
            label: 'Kp (Proporcional)',
            value: _pid.kp,
            min: 0,
            max: 10,
            decimals: 3,
            onChanged: (v) => setState(() => _pid.kp = v),
          ),
          PidSlider(
            label: 'Kd (Derivativo)',
            value: _pid.kd,
            min: 0,
            max: 0.5,
            decimals: 4,
            onChanged: (v) => setState(() => _pid.kd = v),
          ),
          PidSlider(
            label: 'Velocidade Base',
            unit: 'V',
            value: _pid.speed,
            min: 0,
            max: 12,
            decimals: 2,
            onChanged: (v) => setState(() => _pid.speed = v),
          ),
          PidSlider(
            label: 'ESC Power',
            unit: 'V',
            value: _pid.escPower,
            min: 0,
            max: 12,
            decimals: 1,
            onChanged: (v) => setState(() => _pid.escPower = v),
          ),
          PidSlider(
            label: 'Accel Step',
            value: _pid.accelStep,
            min: 0,
            max: 3,
            decimals: 2,
            onChanged: (v) => setState(() => _pid.accelStep = v),
          ),
          const SizedBox(height: 16),
          CommandButton(
            label: 'Enviar Todos',
            icon: Icons.upload,
            outlined: true,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    'PP,${_pid.kp.toStringAsFixed(3)} | PD,${_pid.kd.toStringAsFixed(4)} | PV,${_pid.speed.toStringAsFixed(2)}'),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 3),
              ));
            },
          ),
          const SizedBox(height: 12),
          CommandButton(
            label: 'IR PARA CORRIDA',
            subtitle: 'Passo 4',
            icon: Icons.arrow_forward,
            large: true,
            onPressed: widget.onNext,
          ),
        ],
      ),
    );
  }
}

// ─── Corrida demo ───
class _DemoRace extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final btnHeight =
            (constraints.maxHeight * 0.18).clamp(72.0, 110.0);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _StepBadge('Passo 4 de 4 — Corrida', AppColors.success),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14)),
                child: const Column(
                  children: [
                    Text('Line Follower',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary)),
                    SizedBox(height: 4),
                    Text('Vel: 1.5V  |  Kp: 1.50  |  Kd: 0.015',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: btnHeight,
                child: Material(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('SST → CORRIDA INICIADA!'),
                          backgroundColor: AppColors.success,
                          duration: Duration(seconds: 2)),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow,
                              size: 38, color: Colors.white),
                          const SizedBox(width: 12),
                          Text('INICIAR',
                              style: TextStyle(
                                  fontSize: btnHeight * 0.28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 2)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: btnHeight,
                child: Material(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('SSP → PARADA DE EMERGENCIA!'),
                          backgroundColor: AppColors.error,
                          duration: Duration(seconds: 2)),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.stop,
                              size: 38, color: Colors.white),
                          const SizedBox(width: 12),
                          Text('PARAR',
                              style: TextStyle(
                                  fontSize: btnHeight * 0.28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 2)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Terminal demo ───
class _DemoTerminal extends StatefulWidget {
  @override
  State<_DemoTerminal> createState() => _DemoTerminalState();
}

class _DemoTerminalState extends State<_DemoTerminal> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TerminalProvider>(
      builder: (context, terminal, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) {
            _scroll.jumpTo(_scroll.position.maxScrollExtent);
          }
        });
        return Column(
          children: [
            Expanded(
              child: Container(
                color: AppColors.terminalBackground,
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(8),
                  itemCount: terminal.messages.length,
                  itemBuilder: (context, i) {
                    final msg = terminal.messages[i];
                    final sent = msg.type == TerminalMessageType.sent;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: RichText(
                        text: TextSpan(children: [
                          TextSpan(
                            text: '[${msg.formattedTime}] ',
                            style: AppTheme.terminalStyle.copyWith(
                                color: AppColors.textHint, fontSize: 11),
                          ),
                          TextSpan(
                            text: sent ? '> ' : '< ',
                            style: (sent
                                    ? AppTheme.terminalSentStyle
                                    : AppTheme.terminalStyle)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text: msg.text,
                            style: sent
                                ? AppTheme.terminalSentStyle
                                : AppTheme.terminalStyle,
                          ),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: AppTheme.terminalStyle,
                      decoration: InputDecoration(
                        hintText: 'Comando...',
                        hintStyle: AppTheme.terminalStyle
                            .copyWith(color: AppColors.textHint),
                        filled: true,
                        fillColor: AppColors.terminalBackground,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (v) {
                        if (v.trim().isNotEmpty) {
                          terminal.addSent(v.trim());
                          terminal.addReceived('[DEMO] Comando recebido: $v');
                          _controller.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        final v = _controller.text.trim();
                        if (v.isNotEmpty) {
                          terminal.addSent(v);
                          terminal.addReceived('[DEMO] Comando recebido: $v');
                          _controller.clear();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16)),
                      child: const Icon(Icons.send, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Telemetria demo ───
class _DemoTelemetry extends StatelessWidget {
  final List<TrackPoint> track;
  const _DemoTelemetry({required this.track});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceLight),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: TrackMapWidget(points: track),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Verde = inicio  |  Vermelho = fim  |  Cor = curvatura\nPinch para zoom  •  Double tap para resetar',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _StatRow('Pontos', '${track.length}'),
                _StatRow('Distancia total',
                    '${track.last.distanceM.toStringAsFixed(2)} m'),
                _StatRow(
                    'Curvatura max',
                    '${track.map((p) => p.curvatureDps).reduce((a, b) => a > b ? a : b).toStringAsFixed(1)} dps'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CommandButton(
            label: 'Exportar CSV (demo)',
            icon: Icons.share,
            outlined: true,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('CSV copiado! (modo demo)'),
                    backgroundColor: AppColors.success),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Shared helpers ───

class _StepBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _StepBadge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.linear_scale, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.4),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label, value;
  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DemoSectionTitle extends StatelessWidget {
  final String text;
  const _DemoSectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 1.2));
  }
}
