import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/settings_provider.dart' as settings;
import '../widgets/app_snack_bar.dart';

final GlobalKey<ScaffoldMessengerState> snackbarKey =
    GlobalKey<ScaffoldMessengerState>();

dynamic getSetting(String name) => settings.getSetting(name);

String replaceParamsApiRoute(String apiRoute, Map<String, dynamic> params) {
  var url = apiRoute;
  params.forEach((key, value) {
    url = url.replaceAll('{$key}', value.toString());
  });
  return url;
}

dynamic toSnakeCaseDeep(dynamic value) {
  if (value is Map) {
    return toSnakeCaseMap(value.map((k, v) => MapEntry(k.toString(), v)));
  }
  if (value is List) {
    return value.map(toSnakeCaseDeep).toList();
  }
  return value;
}

Map<String, dynamic> toSnakeCaseMap(Map<String, dynamic> map) {
  final result = <String, dynamic>{};
  map.forEach((key, value) {
    final newKey = key.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
    result[newKey] = toSnakeCaseDeep(value);
  });
  return result;
}

void showNativeSnackBar(
  String message,
  Color color, {
  Duration? duration,
  AppSnackBarType? type,
}) {
  final messenger = snackbarKey.currentState;
  if (messenger == null) return;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      AppSnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: duration,
        type:
            type ??
            (color == Colors.green
                ? AppSnackBarType.success
                : color == Colors.red || color == Colors.redAccent
                ? AppSnackBarType.error
                : color == Colors.orange || color == Colors.orangeAccent
                ? AppSnackBarType.warning
                : AppSnackBarType.info),
      ),
    );
}

Color parseColor(String? hexColor) {
  if (hexColor == null || hexColor.isEmpty) {
    return Colors.grey; // fallback
  }

  try {
    final formatted = hexColor.replaceAll('#', '0xFF');
    return Color(int.parse(formatted));
  } catch (e) {
    return Colors.grey; // fallback seguro
  }
}

String formatDate({required String date, String format = 'dd/MM/yyyy'}) {
  try {
    return formatDateTime(date: DateTime.parse(date), format: format);
  } catch (e) {
    return 'Invalid date';
  }
}

String formatDateTime({required DateTime date, String format = 'dd/MM/yyyy'}) {
  try {
    return DateFormat(format).format(date);
  } catch (e) {
    return 'Invalid date';
  }
}

extension StringExtension on String {
  String capitalizeWords() {
    return split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }
}

extension NullableStringExtension on String? {
  // The text to show for an optional field, falling back to [placeholder]
  // when the value is missing or blank.
  String orPlaceholder([String placeholder = '--']) {
    final String? value = this;

    return value == null || value.trim().isEmpty ? placeholder : value;
  }
}
