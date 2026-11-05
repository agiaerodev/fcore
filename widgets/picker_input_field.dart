import 'package:flutter/material.dart';

class PickerInputField extends StatelessWidget {
  const PickerInputField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.errorText,
    this.enabled = true,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;

  /// Text shown in the field; [placeholder] is shown instead while null.
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  /// Validation message shown under the field, e.g. from a [FormField].
  final String? errorText;

  /// When false the value is shown read-only and tapping does nothing.
  final bool enabled;

  /// Shows a spinner in place of [icon] and blocks the field like [enabled]
  /// does, for values still being resolved.
  final bool isLoading;

  static const _labelStyle = TextStyle(
    color: Color(0xFF40556C),
    fontSize: 14,
  );

  static final _border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFC6D2DE)),
  );

  static final _disabledBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFE0E5ED)),
  );

  @override
  Widget build(BuildContext context) {
    final interactive = enabled && !isLoading;

    return GestureDetector(
      onTap: interactive ? onTap : null,
      child: InputDecorator(
        decoration: InputDecoration(
          enabled: interactive,
          labelText: label,
          labelStyle: _labelStyle,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          floatingLabelStyle: _labelStyle,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          border: _border,
          enabledBorder: _border,
          focusedBorder: _border,
          disabledBorder: _disabledBorder,
          errorText: errorText,
        ),
        child: Row(
          children: [
            if (isLoading)
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF40556C),
                ),
              )
            else
              Icon(
                icon,
                size: 20,
                color: const Color(0xFF40556C),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? placeholder,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: value == null || !interactive
                    ? const Color(0xFF8CA0B3)
                    : const Color(0xFF1A2B47),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
