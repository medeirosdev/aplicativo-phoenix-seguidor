import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/ble/ble_protocol.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/ble_provider.dart';
import '../../providers/telemetry_provider.dart';
import '../../widgets/command_button.dart';
import '../../widgets/track_map_painter.dart';

class TelemetryScreen extends StatelessWidget {
  const TelemetryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('TELEMETRIA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.textSecondary),
            onPressed: () =>
                context.read<TelemetryProvider>().clearAll(),
          ),
        ],
      ),
      body: Consumer2<BleProvider, TelemetryProvider>(
        builder: (context, ble, telemetry, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Botoes de acao
                Row(
                  children: [
                    Expanded(
                      child: CommandButton(
                        label: 'Solicitar Dados',
                        subtitle: 'TP',
                        icon: Icons.download,
                        outlined: true,
                        color: AppColors.info,
                        onPressed: () {
                          ble.sendCommand(BleProtocol.requestTelemetry());
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CommandButton(
                        label: 'Dump Mapa',
                        subtitle: 'GDUMP',
                        icon: Icons.map,
                        outlined: true,
                        color: Colors.tealAccent,
                        onPressed: () {
                          ble.sendCommand(BleProtocol.dumpMap());
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Indicador de recebimento
                if (telemetry.isReceivingMap)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.info,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text('Recebendo dados do mapa...',
                            style: TextStyle(color: AppColors.info)),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Mapa da pista
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceLight),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: TrackMapWidget(
                      points: telemetry.trackPoints,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Estatisticas
                if (telemetry.hasTrack)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _StatRow('Pontos', '${telemetry.trackPoints.length}'),
                        _StatRow('Distancia total',
                            '${telemetry.totalDistance.toStringAsFixed(2)} m'),
                        _StatRow('Curvatura max',
                            '${telemetry.maxCurvature.toStringAsFixed(1)} dps'),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Exportar
                if (telemetry.hasTrack)
                  CommandButton(
                    label: 'Exportar CSV',
                    icon: Icons.share,
                    outlined: true,
                    onPressed: () {
                      final csv = telemetry.exportCsv();
                      Clipboard.setData(ClipboardData(text: csv));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('CSV copiado para clipboard!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
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
