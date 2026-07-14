import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateInputField extends StatelessWidget {
  const DateInputField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.format,
    this.includeTime = false,
    this.placeholder,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? format;
  final bool includeTime;
  final String? placeholder;

  Future<void> openPicker(BuildContext context) async {
    final now = DateTime.now();
    final first = firstDate ?? DateTime(1900);
    final last = lastDate ?? DateTime(2100);

    var initial = value ?? now;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (pickedDate == null) return;

    if (!includeTime) {
      onChanged(pickedDate);
      return;
    }

    if (!context.mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (pickedTime == null) {
      onChanged(pickedDate);
      return;
    }

    onChanged(DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    ));
  }

  String _daySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    return switch (day % 10) {
      1 => 'st',
      2 => 'nd',
      3 => 'rd',
      _ => 'th',
    };
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    if (format != null) {
      String valueFormat = DateFormat(format).format(date);
      return valueFormat;
    }

    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final suffix = _daySuffix(date.day);
    final datePart = '${months[date.month - 1]} ${date.day}$suffix, ${date.year}';
    if (!includeTime) return datePart;
    return '$datePart - ${DateFormat('h:mm a').format(date)}';
  }

  @override
  Widget build(BuildContext context) {
    final formatted = _formatDate(value);
    return GestureDetector(
      onTap: () => openPicker(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Color(0xFF40556C),
            fontSize: 14,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          floatingLabelStyle: const TextStyle(
            color: Color(0xFF40556C),
            fontSize: 14,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
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
            borderSide: const BorderSide(color: Color(0xFFC6D2DE)),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: Color(0xFF40556C),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                formatted ?? placeholder ?? 'Select date',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: formatted == null
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
