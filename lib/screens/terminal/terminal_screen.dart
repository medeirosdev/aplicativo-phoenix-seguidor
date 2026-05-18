import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/ble/ble_protocol.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/ble_provider.dart';
import '../../providers/terminal_provider.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _filterController = TextEditingController();
  bool _showFilter = false;

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
    _inputController.dispose();
    _scrollController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  void _sendCommand() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final terminal = context.read<TerminalProvider>();
    final ble = context.read<BleProvider>();

    final command = terminal.autoAddTerminator
        ? BleProtocol.raw(text)
        : text;

    ble.sendCommand(command);
    terminal.addSent(text);
    _inputController.clear();

    // Scroll para baixo
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('TERMINAL'),
        actions: [
          Consumer<TerminalProvider>(
            builder: (context, terminal, _) {
              return Row(
                children: [
                  // Filtro
                  IconButton(
                    icon: Icon(Icons.search,
                        color: _showFilter
                            ? AppColors.primary
                            : AppColors.textSecondary),
                    onPressed: () {
                      setState(() => _showFilter = !_showFilter);
                      if (!_showFilter) {
                        terminal.setFilter('');
                        _filterController.clear();
                      }
                    },
                  ),
                  // Pausar
                  IconButton(
                    icon: Icon(
                      terminal.paused ? Icons.play_arrow : Icons.pause,
                      color: terminal.paused
                          ? AppColors.warning
                          : AppColors.textSecondary,
                    ),
                    onPressed: terminal.togglePause,
                  ),
                  // Limpar
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.textSecondary),
                    onPressed: terminal.clear,
                  ),
                  // Exportar
                  IconButton(
                    icon: const Icon(Icons.share,
                        color: AppColors.textSecondary),
                    onPressed: () {
                      final log = terminal.exportLog();
                      Clipboard.setData(ClipboardData(text: log));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Log copiado para clipboard')),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de filtro
          if (_showFilter)
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: TextField(
                controller: _filterController,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Filtrar mensagens...',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  prefixIcon: const Icon(Icons.filter_list,
                      size: 18, color: AppColors.textSecondary),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: InputBorder.none,
                ),
                onChanged: (v) =>
                    context.read<TerminalProvider>().setFilter(v),
              ),
            ),

          // Area de output
          Expanded(
            child: Consumer<TerminalProvider>(
              builder: (context, terminal, _) {
                final msgs = terminal.messages;

                // Auto-scroll
                if (!terminal.paused) {
                  _scrollToBottom();
                }

                return Container(
                  color: AppColors.terminalBackground,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: msgs.length,
                    itemBuilder: (context, index) {
                      final msg = msgs[index];
                      final isSent =
                          msg.type == TerminalMessageType.sent;

                      return GestureDetector(
                        onLongPress: () {
                          Clipboard.setData(ClipboardData(text: msg.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Copiado!'),
                                duration: Duration(seconds: 1)),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                if (terminal.showTimestamp)
                                  TextSpan(
                                    text: '[${msg.formattedTime}] ',
                                    style: AppTheme.terminalStyle.copyWith(
                                      color: AppColors.textHint,
                                      fontSize: 11,
                                    ),
                                  ),
                                TextSpan(
                                  text: isSent ? '> ' : '< ',
                                  style: (isSent
                                          ? AppTheme.terminalSentStyle
                                          : AppTheme.terminalStyle)
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                                TextSpan(
                                  text: msg.text,
                                  style: isSent
                                      ? AppTheme.terminalSentStyle
                                      : AppTheme.terminalStyle,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Input
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
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
                        onSubmitted: (_) => _sendCommand(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _sendCommand,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        child: const Icon(Icons.send, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Consumer<TerminalProvider>(
                  builder: (context, terminal, _) {
                    return Row(
                      children: [
                        _TerminalToggle(
                          label: 'Auto \\r',
                          value: terminal.autoAddTerminator,
                          onChanged: terminal.setAutoAddTerminator,
                        ),
                        const SizedBox(width: 16),
                        _TerminalToggle(
                          label: 'Timestamp',
                          value: terminal.showTimestamp,
                          onChanged: terminal.setShowTimestamp,
                        ),
                        const Spacer(),
                        Text(
                          '${terminal.messageCount} msgs',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TerminalToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _TerminalToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v!),
              activeColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
