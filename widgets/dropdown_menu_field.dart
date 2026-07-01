
import 'package:flutter/material.dart';

class DropdownMenuField extends StatelessWidget {
  const DropdownMenuField({
    super.key,
    this.label,
    this.value,
    required this.items,
    required this.onChanged,
    this.width,
  });

  final String? label;
  final String? value;
  final List<DropdownMenuEntry<String>> items;
  final ValueChanged<String?> onChanged;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return DropdownMenuFormField<String>(
      label: Text(label ?? ''),
      initialSelection: value,
      onSelected: onChanged,
      dropdownMenuEntries: items,
      textStyle: const TextStyle(
        color: Color(0xFF162F48),
      ),
      width: width,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFC6D2DE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFC6D2DE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFC6D2DE), width: 1.5),
        ),
      ),
    );
  }
}
