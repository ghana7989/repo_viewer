import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:oauth2/oauth2.dart';
import 'package:repo_viewer/auth/domain/auth_failure.dart';
import 'package:repo_viewer/auth/infrastructure/credential_storage/credential_storage.dart';
import 'package:http/http.dart' as http;

class GithubOAuthHttpClient extends http.BaseClient {
  final httpClient = http.Client();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers["Accept"] = "application/json";
    return httpClient.send(request);
  }
}

class GithubAuthenticator {
  final CredentialsStorage _credentialsStorage;

  GithubAuthenticator(this._credentialsStorage);

  static const clientId = "f09852413f90749d7ca6";
  static const clientSecret = "55e1faebf3a472587b0fc337e8be874c18005f1f";
  static const scopes = ['repo', 'user'];
  static final authorizationEndpoint =
      Uri.parse("https://github.com/login/oauth/authorize");
  static final tokenEndpoint =
      Uri.parse("https://github.com/login/oauth/access_token");
  static final redirectUrl = Uri.parse("http://localhost:3000/callback");

  Future<Credentials?> getSingedInCredentials() async {
    final storeCredentials = await _credentialsStorage.read();
    return storeCredentials;
  }

  Future<bool> isSignedIn() =>
      getSingedInCredentials().then((credentials) => credentials != null);

  AuthorizationCodeGrant createGrant() {
    return AuthorizationCodeGrant(
      clientId,
      authorizationEndpoint,
      redirectUrl,
      secret: clientSecret,
      httpClient: GithubOAuthHttpClient(),
    );
  }

  Uri getAuthorizationUrl(AuthorizationCodeGrant grant) {
    return grant.getAuthorizationUrl(redirectUrl, scopes: scopes);
  }

  Future<Either<AuthFailure, Unit>> handleAuthorizationResponse(
      AuthorizationCodeGrant grant, Map<String, String> queryParams) async {
    try {
      final httpClient = await grant.handleAuthorizationResponse(queryParams);
      await _credentialsStorage.save(httpClient.credentials);
      return right(unit);
    } on FormatException {
      return left(const AuthFailure.server());
    } on AuthorizationException catch (e) {
      return left(AuthFailure.server("${e.error}:-> ${e.description}"));
    } on PlatformException {
      return left(const AuthFailure.storage());
    }
  }
}
