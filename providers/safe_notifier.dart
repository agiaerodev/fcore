import 'package:flutter/foundation.dart';

/// Evita el crash "used after being disposed" cuando una operación
/// asíncrona notifica después de que el provider fue destruido.
mixin SafeNotifier on ChangeNotifier {
  bool _disposed = false;
  bool get isDisposed => _disposed;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Notifica a los listeners solo si el provider sigue vivo.
  void safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }
}
