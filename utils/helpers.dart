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

Map<String, dynamic> toSnakeCaseMap(Map<String, dynamic> map) {
  final result = <String, dynamic>{};
  map.forEach((key, value) {
    final newKey = key.replaceAllMapped(
      RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
    );
    if (value is Map<String, dynamic>) {
      result[newKey] = toSnakeCaseMap(value);
    } else if (value is List) {
      result[newKey] = value
          .map((e) => e is Map<String, dynamic> ? toSnakeCaseMap(e) : e)
          .toList();
    } else {
      result[newKey] = value;
    }
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
