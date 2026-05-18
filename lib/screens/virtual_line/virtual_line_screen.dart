import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ble/ble_protocol.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/ble_provider.dart';
import '../../providers/robot_provider.dart';
import '../../widgets/command_button.dart';
import '../../widgets/pid_slider.dart';
import '../../widgets/status_bar.dart';

class VirtualLineScreen extends StatefulWidget {
  const VirtualLineScreen({super.key});

  @override
  State<VirtualLineScreen> createState() => _VirtualLineScreenState();
}

class _VirtualLineScreenState extends State<VirtualLineScreen> {
  // Speed profile params (locais, envio manual)
  double _spMaxV = 2.0;
  double _spMinV = 1.0;
  double _spThreshold = 50.0;

  // Resolucao do mapa
  double _mapDistM = 0.02;
  double _mapAngleDeg = 10.0;

  // Blend linha fisica / Pure Pursuit
  double _lineBlend = 0.40; // 40% linha, 60% PP
  double _lineKp    = 1.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('LINHA VIRTUAL')),
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
                      // Pure Pursuit params
                      const _SectionTitle('PURE PURSUIT'),
                      const SizedBox(height: 8),

                      PidSlider(
                        label: 'Look-ahead',
                        unit: 'm',
                        value: robot.lookAhead,
                        min: 0.05,
                        max: 0.30,
                        decimals: 3,
                        onChanged: (v) => robot.setLookAhead(v),
                        onChangeEnd: (v) =>
                            ble.sendCommand(BleProtocol.setLookAhead(v)),
                      ),

                      PidSlider(
                        label: 'Ganho (steering)',
                        value: robot.vlGain,
                        min: 0.5,
                        max: 5.0,
                        decimals: 2,
                        onChanged: (v) => robot.setVlGain(v),
                        onChangeEnd: (v) =>
                            ble.sendCommand(BleProtocol.setGain(v)),
                      ),

                      // Drift correction (VD)
                      const _SectionTitle('CORRECAO DE DRIFT  (VD)'),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.info.withOpacity(0.25)),
                        ),
                        child: const Text(
                          'Corrige o drift acumulado da odometria (X,Y) toda vez '
                          'que os sensores frontais detectam a linha fisica. '
                          'Ative apenas se a pista fisica ainda estiver disponível. '
                          'Se nao houver linha no chao, mantenha OFF.',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: CommandButton(
                              label: 'Drift OFF',
                              subtitle: 'VD,0',
                              icon: Icons.gps_off,
                              outlined: !robot.driftCorrection,
                              color: robot.driftCorrection
                                  ? AppColors.surfaceLight
                                  : AppColors.error,
                              onPressed: () {
                                robot.setDriftCorrection(false);
                                ble.sendCommand(
                                    BleProtocol.setDriftCorrection(false));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Correcao de drift DESATIVADA'),
                                    backgroundColor: AppColors.error,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CommandButton(
                              label: 'Drift ON',
                              subtitle: 'VD,1',
                              icon: Icons.gps_fixed,
                              outlined: robot.driftCorrection,
                              color: robot.driftCorrection
                                  ? AppColors.success
                                  : AppColors.surfaceLight,
                              onPressed: () {
                                robot.setDriftCorrection(true);
                                ble.sendCommand(
                                    BleProtocol.setDriftCorrection(true));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Correcao de drift ATIVADA'),
                                    backgroundColor: AppColors.success,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Blend linha física / Pure Pursuit
                      const _SectionTitle('BLEND  LINHA / PURE PURSUIT  (VB)'),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.purpleAccent.withOpacity(0.25)),
                        ),
                        child: Text(
                          'Define quanto o sensor de linha físico influencia '
                          'a correção dos motores enquanto segue a linha virtual.\n'
                          '0% = pure PP (ignora linha física)\n'
                          '40% = padrão (40% linha + 60% PP)\n'
                          '100% = segue só a linha física (igual ao line follower)',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary),
                        ),
                      ),
                      PidSlider(
                        label: 'Blend linha física',
                        unit: '%',
                        value: _lineBlend * 100,
                        min: 0,
                        max: 100,
                        decimals: 0,
                        onChanged: (v) => setState(() => _lineBlend = v / 100),
                      ),
                      PidSlider(
                        label: 'Kp sensor de linha',
                        value: _lineKp,
                        min: 0.1,
                        max: 5.0,
                        decimals: 2,
                        onChanged: (v) => setState(() => _lineKp = v),
                      ),
                      CommandButton(
                        label: 'Aplicar Blend',
                        subtitle:
                            'VB,${_lineBlend.toStringAsFixed(2)}  +  VK,${_lineKp.toStringAsFixed(3)}',
                        icon: Icons.tune,
                        color: Colors.purpleAccent,
                        onPressed: () {
                          ble.sendCommand(
                              BleProtocol.setLineBlend(_lineBlend));
                          ble.sendCommand(
                              BleProtocol.setLineKp(_lineKp));
                          final pct = (_lineBlend * 100).toStringAsFixed(0);
                          final pp  = (100 - _lineBlend * 100).toStringAsFixed(0);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                'Blend: $pct% linha + $pp% PP  |  Kp=$_lineKp'),
                            backgroundColor: Colors.purpleAccent,
                          ));
                        },
                      ),

                      const SizedBox(height: 24),

                      // Mapeamento
                      const _SectionTitle('MAPEAMENTO'),
                      const SizedBox(height: 4),
                      // Aviso: mapeamento já ativo por padrão no firmware
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.success.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: AppColors.success, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Mapeamento ativo por padrao no firmware '
                                '(map_on_giroscopio = true). '
                                'Use "Confirmar" apenas se necessario.',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: CommandButton(
                              label: 'Confirmar Mapa',
                              subtitle: 'GMAP — ja ativo por padrao',
                              icon: Icons.map,
                              outlined: true,
                              color: AppColors.info,
                              onPressed: () {
                                ble.sendCommand(BleProtocol.enableMapping());
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'GMAP enviado — mapeamento confirmado.'),
                                    backgroundColor: AppColors.info,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CommandButton(
                              label: 'Exportar Mapa',
                              subtitle: 'GDUMP — so no STOP_STATE',
                              icon: Icons.download,
                              outlined: true,
                              color: Colors.tealAccent,
                              onPressed: () {
                                ble.sendCommand(BleProtocol.dumpMap());
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Resolucao do mapa
                      const _SectionTitle('RESOLUCAO DO MAPEAMENTO'),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.info.withOpacity(0.2)),
                        ),
                        child: const Text(
                          'Amostragem dual: grava ponto quando distância ≥ D  OU  ângulo ≥ A.\n'
                          'Reduzir o ângulo aumenta a densidade em curvas fechadas.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                      PidSlider(
                        label: 'Distância mínima',
                        unit: ' cm',
                        value: _mapDistM * 100,
                        min: 0.5,
                        max: 5.0,
                        decimals: 1,
                        onChanged: (v) => setState(() => _mapDistM = v / 100),
                      ),
                      PidSlider(
                        label: 'Ângulo mínimo',
                        unit: '°',
                        value: _mapAngleDeg,
                        min: 1.0,
                        max: 30.0,
                        decimals: 1,
                        onChanged: (v) => setState(() => _mapAngleDeg = v),
                      ),
                      CommandButton(
                        label: 'Aplicar Resolução',
                        subtitle: 'VM,${_mapDistM.toStringAsFixed(3)},${_mapAngleDeg.toStringAsFixed(1)}',
                        icon: Icons.grain,
                        outlined: true,
                        color: AppColors.info,
                        onPressed: () {
                          ble.sendCommand(BleProtocol.setMapResolution(_mapDistM, _mapAngleDeg));
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                              'Resolucao: ${(_mapDistM * 100).toStringAsFixed(1)}cm OU ${_mapAngleDeg.toStringAsFixed(1)}°',
                            ),
                            backgroundColor: AppColors.info,
                          ));
                        },
                      ),

                      const SizedBox(height: 24),

                      // Suavizacao
                      const _SectionTitle('SUAVIZACAO DA TRAJETORIA'),
                      const SizedBox(height: 8),

                      PidSlider(
                        label: 'Janela (Moving Average)',
                        value: robot.smoothWindow.toDouble(),
                        min: 1,
                        max: 50,
                        decimals: 0,
                        onChanged: (v) => robot.setSmoothWindow(v.round()),
                        onChangeEnd: (v) => ble.sendCommand(
                            BleProtocol.smoothTrajectory(v.round())),
                      ),

                      const SizedBox(height: 24),

                      // Speed Profile
                      const _SectionTitle('PERFIL DE VELOCIDADE'),
                      const SizedBox(height: 8),

                      PidSlider(
                        label: 'Max Voltage',
                        unit: 'V',
                        value: _spMaxV,
                        min: 0.5,
                        max: 12.0,
                        decimals: 1,
                        onChanged: (v) => setState(() => _spMaxV = v),
                      ),
                      PidSlider(
                        label: 'Min Voltage',
                        unit: 'V',
                        value: _spMinV,
                        min: 0.5,
                        max: 6.0,
                        decimals: 1,
                        onChanged: (v) => setState(() => _spMinV = v),
                      ),
                      PidSlider(
                        label: 'Threshold',
                        unit: ' dps',
                        value: _spThreshold,
                        min: 10,
                        max: 500,
                        decimals: 0,
                        onChanged: (v) => setState(() => _spThreshold = v),
                      ),

                      const SizedBox(height: 8),
                      CommandButton(
                        label: 'Calcular Speed Profile',
                        subtitle:
                            'VP,${_spMaxV.toStringAsFixed(1)},${_spMinV.toStringAsFixed(1)},${_spThreshold.toStringAsFixed(0)}',
                        icon: Icons.calculate,
                        onPressed: () {
                          ble.sendCommand(BleProtocol.computeSpeedProfile(
                              _spMaxV, _spMinV, _spThreshold));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Speed profile calculado!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Consultar
                      CommandButton(
                        label: 'Consultar Parametros',
                        subtitle: 'VC',
                        icon: Icons.info_outline,
                        outlined: true,
                        onPressed: () {
                          ble.sendCommand(BleProtocol.consultVirtualLine());
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
