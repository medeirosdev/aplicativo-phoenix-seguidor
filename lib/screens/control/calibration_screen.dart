import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ble/ble_protocol.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/ble_provider.dart';
import '../../widgets/command_button.dart';
import '../../widgets/status_bar.dart';
import '../control/pid_screen.dart';

enum CalibrationType { manual, manualEeprom, fromEeprom }

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  CalibrationType _selectedType = CalibrationType.fromEeprom;

  @override
  Widget build(BuildContext context) {
    final ble = context.read<BleProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('CALIBRACAO'), actions: [
        _StepBadge(step: 2, total: 4),
        const SizedBox(width: 12),
      ]),
      body: Column(
        children: [
          const StatusBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── PASSO A: Giroscópio (robô PARADO) ──────────────────
                  _StepRow(number: 'A', label: 'GIROSCÓPIO  —  robô parado no chão'),
                  const SizedBox(height: 8),
                  CommandButton(
                    label: 'Calibrar Giroscópio',
                    subtitle: 'GC · 2000 amostras · ~10 segundos',
                    icon: Icons.rotate_right,
                    color: AppColors.info,
                    onPressed: () {
                      ble.sendCommand(BleProtocol.calibrateGyro());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Calibrando giroscópio... mantenha o robô PARADO'),
                          backgroundColor: AppColors.info,
                          duration: Duration(seconds: 12),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // ── PASSO B: Tipo de calibração dos sensores ────────────
                  _StepRow(number: 'B', label: 'TIPO DE CALIBRAÇÃO DOS SENSORES'),
                  const SizedBox(height: 8),

                  _CalibOption(
                    label: 'Manual',
                    subtitle: 'KM0 · calibra agora, sem salvar',
                    icon: Icons.touch_app,
                    selected: _selectedType == CalibrationType.manual,
                    onTap: () {
                      setState(() => _selectedType = CalibrationType.manual);
                      ble.sendCommand(BleProtocol.calibrateManual());
                    },
                  ),
                  const SizedBox(height: 8),
                  _CalibOption(
                    label: 'Manual + salvar EEPROM',
                    subtitle: 'KME · calibra e grava para próximas vezes',
                    icon: Icons.save,
                    selected: _selectedType == CalibrationType.manualEeprom,
                    onTap: () {
                      setState(() => _selectedType = CalibrationType.manualEeprom);
                      ble.sendCommand(BleProtocol.calibrateManualEeprom());
                    },
                  ),
                  const SizedBox(height: 8),
                  _CalibOption(
                    label: 'Carregar da EEPROM',
                    subtitle: 'KEE · usa calibração salva, não precisa mover',
                    icon: Icons.memory,
                    selected: _selectedType == CalibrationType.fromEeprom,
                    onTap: () {
                      setState(() => _selectedType = CalibrationType.fromEeprom);
                      ble.sendCommand(BleProtocol.calibrateFromEeprom());
                    },
                  ),

                  const SizedBox(height: 28),

                  // ── PASSO C: Executar ────────────────────────────────────
                  _StepRow(
                    number: 'C',
                    label: _selectedType == CalibrationType.fromEeprom
                        ? 'EXECUTAR  —  sem mover o robô'
                        : 'EXECUTAR  —  mova o robô sobre a linha',
                  ),
                  const SizedBox(height: 8),

                  if (_selectedType != CalibrationType.fromEeprom)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.warning.withOpacity(0.25)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: AppColors.warning, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Passe o robô sobre a linha preta e a superfície '
                              'branca enquanto a calibração estiver rodando.',
                              style: TextStyle(fontSize: 11, color: AppColors.warning),
                            ),
                          ),
                        ],
                      ),
                    ),

                  CommandButton(
                    label: 'EXECUTAR E IR PARA PID',
                    subtitle: 'KOK → Passo 3',
                    icon: Icons.arrow_forward_rounded,
                    large: true,
                    color: AppColors.success,
                    onPressed: () {
                      ble.sendCommand(BleProtocol.startCalibration());
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const PidScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  CommandButton(
                    label: 'Apenas Executar',
                    subtitle: 'KOK — sem mudar de tela',
                    icon: Icons.check,
                    outlined: true,
                    color: AppColors.success,
                    onPressed: () {
                      ble.sendCommand(BleProtocol.startCalibration());
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _selectedType == CalibrationType.fromEeprom
                                ? 'Carregando calibração da EEPROM...'
                                : 'Calibração iniciada! Mova o robô sobre a linha.',
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalibOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CalibOption({
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
                  color: selected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        )),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
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

class _StepRow extends StatelessWidget {
  final String number;
  final String label;
  const _StepRow({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.info,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 1.1,
          ),
        ),
      ],
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
        color: AppColors.info.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.info.withOpacity(0.4)),
      ),
      child: Text(
        'Passo $step de $total',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.info,
        ),
      ),
    );
  }
}
