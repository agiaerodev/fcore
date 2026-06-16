import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  final _storage = const FlutterSecureStorage();

  Future<bool> hasSeenWelcome() async {
    final seen = await _storage.read(key: 'hasSeenWelcome');
    return seen == 'true';
  }

  Future<void> markWelcomeSeen() async {
    await _storage.write(key: 'hasSeenWelcome', value: 'true');
  }
}