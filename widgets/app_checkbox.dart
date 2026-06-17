import 'package:flutter/material.dart';

class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.title,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final checkbox = Checkbox(
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF2292C7),
      side: const BorderSide(
        color: Color(0xFF40556C),
      ),
    );

    if (title == null || title!.isEmpty) {
      return checkbox;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        checkbox,
        Flexible(
          child: Text(
            title!,
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.w400
            ),
          ),
        ),
      ],
    );
  }
}