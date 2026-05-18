import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/ble_provider.dart';
import '../../providers/terminal_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('CONFIGURACOES')),
      body: Consumer2<BleProvider, TerminalProvider>(
        builder: (context, ble, terminal, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Conexao
              _SectionHeader('CONEXAO'),
              _SettingsTile(
                icon: Icons.bluetooth,
                title: 'Auto-reconnect',
                subtitle: 'Reconectar automaticamente ao perder conexao',
                trailing: Switch(
                  value: ble.autoReconnect,
                  onChanged: (v) => ble.autoReconnect = v,
                ),
              ),

              const SizedBox(height: 20),

              // Terminal
              _SectionHeader('TERMINAL'),
              _SettingsTile(
                icon: Icons.keyboard_return,
                title: 'Adicionar \\r automaticamente',
                subtitle: 'Adiciona carriage return ao final dos comandos',
                trailing: Switch(
                  value: terminal.autoAddTerminator,
                  onChanged: terminal.setAutoAddTerminator,
                ),
              ),
              _SettingsTile(
                icon: Icons.access_time,
                title: 'Mostrar timestamp',
                subtitle: 'Exibe horario em cada mensagem',
                trailing: Switch(
                  value: terminal.showTimestamp,
                  onChanged: terminal.setShowTimestamp,
                ),
              ),

              const SizedBox(height: 20),

              // Sobre
              _SectionHeader('SOBRE'),
              _SettingsTile(
                icon: Icons.precision_manufacturing,
                title: 'Phoenix App',
                subtitle: 'v1.0.0 - Phoenix Unicamp',
              ),
              _SettingsTile(
                icon: Icons.smart_toy,
                title: 'Robo Bia (PHX-1)',
                subtitle: 'Seguidor de linha - Senna v4',
              ),
              _SettingsTile(
                icon: Icons.bluetooth,
                title: 'BLE Service',
                subtitle: 'ab0828b1-198e-4351-b779-901fa0e0371e',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(icon, color: AppColors.primary, size: 22),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style:
              const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: trailing,
      ),
    );
  }
}
