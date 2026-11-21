import 'package:flutter/foundation.dart';

/// URL base de la API FastAPI.
///
/// - Web / escritorio / simulador iOS: http://127.0.0.1:8000
/// - Emulador de Android: http://10.0.2.2:8000 (127.0.0.1 apuntaría al propio emulador)
/// - Celular físico (misma red Wi-Fi que la PC):
///   flutter run --dart-define=API_URL=http://192.168.1.50:8000
class ApiConfig {
  static const String _override = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  /// Prefijo de la versión de la API.
  static String get apiUrl => '$baseUrl/api/v1';
}
