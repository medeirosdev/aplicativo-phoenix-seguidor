import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class PidSlider extends StatefulWidget {
  final String label;
  final String unit;
  final double value;
  final double min;
  final double max;
  final int decimals;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  const PidSlider({
    super.key,
    required this.label,
    this.unit = '',
    required this.value,
    required this.min,
    required this.max,
    this.decimals = 3,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  State<PidSlider> createState() => _PidSliderState();
}

class _PidSliderState extends State<PidSlider> {
  late TextEditingController _textController;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
        text: widget.value.toStringAsFixed(widget.decimals));
  }

  @override
  void didUpdateWidget(PidSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing) {
      _textController.text = widget.value.toStringAsFixed(widget.decimals);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onTextSubmitted(String text) {
    final value = double.tryParse(text);
    if (value != null) {
      final clamped = value.clamp(widget.min, widget.max);
      widget.onChanged(clamped);
      widget.onChangeEnd?.call(clamped);
    }
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              // Valor - tap para editar
              GestureDetector(
                onTap: () => setState(() => _editing = true),
                child: _editing
                    ? SizedBox(
                        width: 80,
                        height: 32,
                        child: TextField(
                          controller: _textController,
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            isDense: true,
                          ),
                          onSubmitted: _onTextSubmitted,
                          onTapOutside: (_) {
                            _onTextSubmitted(_textController.text);
                          },
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${widget.value.toStringAsFixed(widget.decimals)}${widget.unit}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          SliderTheme(
            data: Theme.of(context).sliderTheme.copyWith(
                  trackHeight: 4,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 8),
                ),
            child: Slider(
              value: widget.value.clamp(widget.min, widget.max),
              min: widget.min,
              max: widget.max,
              onChanged: (v) {
                widget.onChanged(
                    double.parse(v.toStringAsFixed(widget.decimals)));
              },
              onChangeEnd: widget.onChangeEnd,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.min.toStringAsFixed(widget.decimals > 1 ? 1 : 0),
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary),
              ),
              Text(
                widget.max.toStringAsFixed(widget.decimals > 1 ? 1 : 0),
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
