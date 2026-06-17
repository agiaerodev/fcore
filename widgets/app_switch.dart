import 'package:flutter/material.dart';

class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String? title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final switchWidget = Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: Color(0xFF2292C7),
      inactiveTrackColor: Color(0xFFE9EFF7),
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return Color(0xFF718499);
      }),
    );

    if (title == null && subtitle == null) return switchWidget;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        switchWidget,
        if (title != null || subtitle != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null) Text(title!),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
      ],
    );
  }
}