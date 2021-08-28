import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oauth2/src/credentials.dart';
import 'package:repo_viewer/auth/infrastructure/credential_storage/credential_storage.dart';

class SecureCredentialsStorage implements CredentialsStorage {
  static const _key = "oauth_2_credentials";

  final FlutterSecureStorage _storage;

  SecureCredentialsStorage(this._storage);

// Here we are creating a class variable for caching the credentials the user
// passed
  Credentials? _cachedCredentials;

  @override
  Future<Credentials?> read() async {
    if (_cachedCredentials != null) return _cachedCredentials;

    final credentialsJSON = await _storage.read(key: _key);

    if (credentialsJSON == null) return null;

// Try to catch every Exception whenever it is possible
    try {
      return _cachedCredentials = Credentials.fromJson(credentialsJSON);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(Credentials credentials) {
    _cachedCredentials = credentials;
    return _storage.write(key: _key, value: credentials.toJson());
  }

  @override
  Future<void> clear() {
    _cachedCredentials = null;
    return _storage.delete(key: _key);
  }
}
