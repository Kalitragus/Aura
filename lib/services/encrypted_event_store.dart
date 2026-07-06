import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Piccola interfaccia per rendere testabile la custodia della chiave.
abstract class SecureKeyStore {
  Future<String?> read(String key);

  Future<void> write(String key, String? value);
}

/// Adapter reale: su Android passa da Android Keystore tramite il plugin.
class FlutterSecureKeyStore implements SecureKeyStore {
  const FlutterSecureKeyStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String? value) =>
      _storage.write(key: key, value: value);
}

/// Storage eventi cifrato: SharedPreferences contiene solo ciphertext; la
/// chiave AES resta nel secure storage della piattaforma.
class EncryptedEventStore {
  EncryptedEventStore({
    SecureKeyStore secureKeyStore = const FlutterSecureKeyStore(),
    Future<SharedPreferences> Function()? preferencesProvider,
    Cipher? cipher,
  })  : _secureKeyStore = secureKeyStore,
        _preferencesProvider =
            preferencesProvider ?? SharedPreferences.getInstance,
        _cipher = cipher ?? AesGcm.with256bits();

  static const legacyStorageKey = 'events_v1';
  static const encryptedStorageKey = 'events_v2_encrypted';
  static const keyStorageKey = 'events_v2_key';

  final SecureKeyStore _secureKeyStore;
  final Future<SharedPreferences> Function() _preferencesProvider;
  final Cipher _cipher;

  /// Legge il JSON eventi. Se trova il vecchio storage in chiaro, lo migra.
  Future<String?> read() async {
    final prefs = await _preferencesProvider();
    final encrypted = prefs.getString(encryptedStorageKey);
    if (encrypted != null) {
      return _decrypt(encrypted);
    }

    final legacy = prefs.getString(legacyStorageKey);
    if (legacy != null) {
      await write(legacy);
      await prefs.remove(legacyStorageKey);
      return legacy;
    }

    return null;
  }

  /// Cifra e salva il JSON eventi.
  Future<void> write(String plainJson) async {
    final prefs = await _preferencesProvider();
    final encrypted = await _encrypt(plainJson);
    await prefs.setString(encryptedStorageKey, encrypted);
    await prefs.remove(legacyStorageKey);
  }

  Future<String> _encrypt(String plainJson) async {
    final key = await _loadOrCreateKey();
    final secretBox = await _cipher.encrypt(
      utf8.encode(plainJson),
      secretKey: key,
    );
    return jsonEncode({
      'v': 1,
      'alg': 'AES-GCM-256',
      'box': base64Encode(secretBox.concatenation()),
    });
  }

  Future<String> _decrypt(String encryptedJson) async {
    final decoded = jsonDecode(encryptedJson) as Map<String, dynamic>;
    if (decoded['v'] != 1 || decoded['alg'] != 'AES-GCM-256') {
      throw const FormatException('Formato storage cifrato non supportato.');
    }

    final box = SecretBox.fromConcatenation(
      base64Decode(decoded['box'] as String),
      nonceLength: _cipher.nonceLength,
      macLength: _cipher.macAlgorithm.macLength,
    );
    final clearBytes = await _cipher.decrypt(
      box,
      secretKey: await _loadOrCreateKey(),
    );
    return utf8.decode(clearBytes);
  }

  Future<SecretKey> _loadOrCreateKey() async {
    final encoded = await _secureKeyStore.read(keyStorageKey);
    if (encoded != null) {
      return SecretKey(base64Decode(encoded));
    }

    final key = await _cipher.newSecretKey();
    final bytes = await key.extractBytes();
    await _secureKeyStore.write(keyStorageKey, base64Encode(bytes));
    return key;
  }
}
