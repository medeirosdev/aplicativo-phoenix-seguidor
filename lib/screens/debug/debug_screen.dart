import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/ble/ble_protocol.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/ble_provider.dart';
import '../../providers/terminal_provider.dart';

enum DebugFilter { off, battery, ir, frontalSensors }

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  DebugFilter _activeFilter = DebugFilter.off;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final terminal = context.read<TerminalProvider>();
      final ble = context.read<BleProvider>();
      terminal.listenToBle(ble);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setFilter(DebugFilter filter, BleProvider ble) {
    setState(() => _activeFilter = filter);

    switch (filter) {
      case DebugFilter.off:
        ble.sendCommand(BleProtocol.debugOff());
        break;
      case DebugFilter.battery:
        ble.sendCommand(BleProtocol.debugBattery());
        break;
      case DebugFilter.ir:
        ble.sendCommand(BleProtocol.debugIR());
        break;
      case DebugFilter.frontalSensors:
        ble.sendCommand(BleProtocol.debugFrontalSensors());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.read<BleProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('DEBUG'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.textSecondary),
            onPressed: () => context.read<TerminalProvider>().clear(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.surface,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _DebugButton(
                        label: 'Bateria',
                        icon: Icons.battery_full,
                        color: AppColors.success,
                        active: _activeFilter == DebugFilter.battery,
                        onTap: () => _setFilter(DebugFilter.battery, ble),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DebugButton(
                        label: 'IR',
                        icon: Icons.settings_remote,
                        color: AppColors.warning,
                        active: _activeFilter == DebugFilter.ir,
                        onTap: () => _setFilter(DebugFilter.ir, ble),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DebugButton(
                        label: 'Sensores',
                        icon: Icons.sensors,
                        color: AppColors.info,
                        active: _activeFilter == DebugFilter.frontalSensors,
                        onTap: () =>
                            _setFilter(DebugFilter.frontalSensors, ble),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: _DebugButton(
                    label: 'Desligar Debug',
                    icon: Icons.close,
                    color: AppColors.error,
                    active: _activeFilter == DebugFilter.off,
                    onTap: () => _setFilter(DebugFilter.off, ble),
                  ),
                ),
              ],
            ),
          ),

          // Output
          Expanded(
            child: Consumer<TerminalProvider>(
              builder: (context, terminal, _) {
                final msgs = terminal.messages
                    .where(
                        (m) => m.type == TerminalMessageType.received)
                    .toList();

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients &&
                      !terminal.paused) {
                    _scrollController.jumpTo(
                        _scrollController.position.maxScrollExtent);
                  }
                });

                return Container(
                  color: AppColors.terminalBackground,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: msgs.length,
                    itemBuilder: (context, index) {
                      final msg = msgs[index];
                      return GestureDetector(
                        onLongPress: () {
                          Clipboard.setData(ClipboardData(text: msg.text));
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Text(
                            '${msg.formattedTime}  ${msg.text}',
                            style: AppTheme.terminalStyle,
                          ),
                        ),
                      );
                    },
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

class _DebugButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _DebugButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? color.withOpacity(0.2) : AppColors.card,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: active ? color : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: active ? color : AppColors.textSecondary, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
