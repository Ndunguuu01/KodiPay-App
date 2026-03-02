import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure key-value store backed by the OS keychain.
/// - Android: EncryptedSharedPreferences (AES-256)
/// - iOS: Keychain
///
/// Use this for ALL sensitive data: JWT tokens, user IDs, session state.
/// Do NOT use SharedPreferences for tokens.
class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ── Key constants ──────────────────────────────────────────────────────────
  static const _keyToken = 'accessToken';
  static const _keyUserId = 'userId';
  static const _keyUserRole = 'userRole';
  static const _keyUserName = 'userName';

  // ── Write ──────────────────────────────────────────────────────────────────
  static Future<void> saveToken(String token) =>
      _storage.write(key: _keyToken, value: token);
  static Future<void> saveUserId(int id) =>
      _storage.write(key: _keyUserId, value: id.toString());
  static Future<void> saveUserRole(String role) =>
      _storage.write(key: _keyUserRole, value: role);
  static Future<void> saveUserName(String name) =>
      _storage.write(key: _keyUserName, value: name);

  static Future<void> saveSession({
    required String token,
    required int userId,
    required String role,
    required String name,
  }) async {
    await Future.wait([
      saveToken(token),
      saveUserId(userId),
      saveUserRole(role),
      saveUserName(name),
    ]);
  }

  // ── Read ───────────────────────────────────────────────────────────────────
  static Future<String?> getToken() => _storage.read(key: _keyToken);
  static Future<int?> getUserId() async {
    final val = await _storage.read(key: _keyUserId);
    return val != null ? int.tryParse(val) : null;
  }

  static Future<String?> getUserRole() => _storage.read(key: _keyUserRole);
  static Future<String?> getUserName() => _storage.read(key: _keyUserName);

  // ── Delete ─────────────────────────────────────────────────────────────────
  static Future<void> clearSession() => _storage.deleteAll();

  // ── Utility ────────────────────────────────────────────────────────────────
  static Future<bool> hasSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
