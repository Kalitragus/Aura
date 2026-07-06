import 'package:aura/services/encrypted_event_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemorySecureKeyStore implements SecureKeyStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String? value) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('salva gli eventi come payload cifrato', () async {
    const rawJson = '[{"id":"1","note":"dato sensibile"}]';
    final keyStore = MemorySecureKeyStore();
    final store = EncryptedEventStore(secureKeyStore: keyStore);

    await store.write(rawJson);

    final prefs = await SharedPreferences.getInstance();
    final encrypted = prefs.getString(EncryptedEventStore.encryptedStorageKey);

    expect(encrypted, isNotNull);
    expect(encrypted, isNot(contains('dato sensibile')));
    expect(prefs.getString(EncryptedEventStore.legacyStorageKey), isNull);
    expect(keyStore.values, contains(EncryptedEventStore.keyStorageKey));
    expect(await store.read(), rawJson);
  });

  test('migra il vecchio storage in chiaro al primo caricamento', () async {
    const rawJson = '[{"id":"legacy","note":"vecchio dato"}]';
    SharedPreferences.setMockInitialValues({
      EncryptedEventStore.legacyStorageKey: rawJson,
    });

    final store = EncryptedEventStore(secureKeyStore: MemorySecureKeyStore());

    expect(await store.read(), rawJson);

    final prefs = await SharedPreferences.getInstance();
    final encrypted = prefs.getString(EncryptedEventStore.encryptedStorageKey);

    expect(prefs.getString(EncryptedEventStore.legacyStorageKey), isNull);
    expect(encrypted, isNotNull);
    expect(encrypted, isNot(contains('vecchio dato')));
    expect(await store.read(), rawJson);
  });
}
