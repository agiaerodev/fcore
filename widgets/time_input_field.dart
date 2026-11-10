import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'picker_input_field.dart';

/// Time-only counterpart of `DateInputField`.
class TimeInputField extends StatelessWidget {
  const TimeInputField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.placeholder,
    this.validator,
    this.use24HourFormat = false,
    this.initialEntryMode = TimePickerEntryMode.input,
    this.isLoading = false,
  });

  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay> onChanged;
  final String? placeholder;
  final bool use24HourFormat;
  final TimePickerEntryMode initialEntryMode;

  /// Shows a spinner and blocks the field while the time is being resolved.
  final bool isLoading;

  /// When set, the field joins the enclosing [Form] and shows the
  /// validation message under it.
  final FormFieldValidator<TimeOfDay>? validator;

  Future<void> openPicker(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: value ?? TimeOfDay.now(),
      initialEntryMode: initialEntryMode,
      builder: use24HourFormat
        ? (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          )
        : null,
    );
    if (picked == null) return;
    onChanged(picked);
  }

  String? _formatTime(TimeOfDay? time) {
    if (time == null) return null;
    final format = use24HourFormat ? 'HH:mm' : 'h:mm a';
    return DateFormat(format).format(DateTime(2000, 1, 1, time.hour, time.minute));
  }

  Widget _buildPicker(BuildContext context, {String? errorText}) {
    return PickerInputField(
      label: label,
      icon: Icons.access_time_outlined,
      value: _formatTime(value),
      placeholder: placeholder ?? 'Select time',
      errorText: errorText,
      isLoading: isLoading,
      onTap: () => openPicker(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final validator = this.validator;
    if (validator == null) return _buildPicker(context);

    return FormField<TimeOfDay>(
      // Keeps the validator in sync with the value picked outside the form.
      key: ValueKey(value),
      initialValue: value,
      validator: validator,
      builder: (field) => _buildPicker(context, errorText: field.errorText),
    );
  }
}
