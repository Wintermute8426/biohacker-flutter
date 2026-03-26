import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for HIPAA-compliant data encryption
/// Uses platform-specific secure storage (Keychain on iOS, KeyStore on Android)
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Keys for secure storage
  static const String _keySessionToken = 'session_token';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyHipaaAcknowledged = 'hipaa_acknowledged';
  static const String _keyHipaaAcknowledgedAt = 'hipaa_acknowledged_at';
  static const String _keyLastActivityTimestamp = 'last_activity_timestamp';

  // Session token management
  Future<void> setSessionToken(String token) async {
    await _storage.write(key: _keySessionToken, value: token);
  }

  Future<String?> getSessionToken() async {
    return await _storage.read(key: _keySessionToken);
  }

  Future<void> clearSessionToken() async {
    await _storage.delete(key: _keySessionToken);
  }

  // Biometric preference
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
  }

  Future<bool> getBiometricEnabled() async {
    final value = await _storage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  // HIPAA acknowledgment
  Future<void> setHipaaAcknowledged(bool acknowledged) async {
    await _storage.write(key: _keyHipaaAcknowledged, value: acknowledged.toString());
    if (acknowledged) {
      await _storage.write(
        key: _keyHipaaAcknowledgedAt,
        value: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<bool> getHipaaAcknowledged() async {
    final value = await _storage.read(key: _keyHipaaAcknowledged);
    return value == 'true';
  }

  Future<String?> getHipaaAcknowledgedAt() async {
    return await _storage.read(key: _keyHipaaAcknowledgedAt);
  }

  // Activity tracking for session timeout
  Future<void> setLastActivityTimestamp(int timestamp) async {
    await _storage.write(key: _keyLastActivityTimestamp, value: timestamp.toString());
  }

  Future<int?> getLastActivityTimestamp() async {
    final value = await _storage.read(key: _keyLastActivityTimestamp);
    return value != null ? int.tryParse(value) : null;
  }

  Future<void> clearLastActivityTimestamp() async {
    await _storage.delete(key: _keyLastActivityTimestamp);
  }

  // Clear all secure storage (on logout)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
