import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';

class CommandButton extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color? color;
  final Color? textColor;
  final bool large;
  final bool outlined;
  final bool enabled;

  const CommandButton({
    super.key,
    required this.label,
    this.subtitle,
    this.icon,
    required this.onPressed,
    this.color,
    this.textColor,
    this.large = false,
    this.outlined = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final btnColor = color ?? AppColors.primary;
    final txtColor = textColor ?? Colors.white;

    return SizedBox(
      height: large ? 72 : 52,
      child: Material(
        color: outlined
            ? Colors.transparent
            : (enabled ? btnColor : btnColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled
              ? () {
                  HapticFeedback.mediumImpact();
                  onPressed();
                }
              : null,
          child: Container(
            decoration: outlined
                ? BoxDecoration(
                    border: Border.all(
                        color: enabled
                            ? btnColor
                            : btnColor.withOpacity(0.3),
                        width: 2),
                    borderRadius: BorderRadius.circular(14),
                  )
                : null,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon,
                      color: outlined ? btnColor : txtColor,
                      size: large ? 26 : 22),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: outlined ? btnColor : txtColor,
                          fontSize: large ? 16 : 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: (outlined ? btnColor : txtColor)
                                .withOpacity(0.7),
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botao de emergencia - sempre vermelho e grande
class EmergencyStopButton extends StatelessWidget {
  final VoidCallback onPressed;
  const EmergencyStopButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return CommandButton(
      label: 'PARADA DE EMERGENCIA',
      icon: Icons.stop_circle,
      onPressed: () {
        HapticFeedback.heavyImpact();
        onPressed();
      },
      color: AppColors.error,
      large: true,
    );
  }
}
