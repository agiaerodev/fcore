import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final GlobalKey<ScaffoldMessengerState> snackbarKey = GlobalKey<ScaffoldMessengerState>();

String replaceParamsApiRoute(
    String apiRoute,
    Map<String, dynamic> params,
    ) {
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

void showNativeSnackBar(String message, Color color) {
  snackbarKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 1), // menos tiempo
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

String formatDate({ 
  required String date,
  String format = 'dd/MM/yyyy',
}) {
  try {
    DateTime parsedDate = DateTime.parse(date);
    
    String formattedDate = DateFormat(format).format(parsedDate);
    
    return formattedDate;
  } catch (e) {
    return 'Invalid date'; 
  }
}

extension StringExtension on String {
  String capitalizeWords() {
    return split(' ')
      .map((word) => word.isEmpty
        ? word
        : word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
  }
}
