import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:oauth2/oauth2.dart';
import 'package:repo_viewer/auth/domain/auth_failure.dart';
import 'package:repo_viewer/auth/infrastructure/credential_storage/credential_storage.dart';
import 'package:http/http.dart' as http;
import 'package:repo_viewer/core/shared/encoders.dart';

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
  final Dio _dio;

  GithubAuthenticator(this._credentialsStorage, this._dio);

  static const clientId = "f09852413f90749d7ca6";
  static const clientSecret = "55e1faebf3a472587b0fc337e8be874c18005f1f";
  static const scopes = ['repo', 'user'];
  static final authorizationEndpoint =
      Uri.parse("https://github.com/login/oauth/authorize");
  static final tokenEndpoint =
      Uri.parse("https://github.com/login/oauth/access_token");
  static final revocationEndPoint =
      Uri.parse("https://api.github.com/applications/$clientId/token");
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

  Future<Either<AuthFailure, Unit>> signOut() async {
    final accessToken = await _credentialsStorage
        .read()
        .then((credentials) => credentials?.accessToken);
    // As encode method takes only list of integers we need to convert characters into 0's and 1's
    // that is done by using utf
    //  we created a custom chained codec called stringToBase64
    final usernameAndPassword =
        stringToBase64.encode("$clientId:$clientSecret");

    try {
      _dio.deleteUri(
        revocationEndPoint,
        data: {
          "access_token": accessToken,
        },
        options: Options(
          headers: {
            // Basic Authorization will take clientId and secret in base64 encoding
            'Authorization': "basic $usernameAndPassword",
          },
        ),
      );
      await _credentialsStorage.clear();
      return right(unit);
    } on PlatformException {
      return left(const AuthFailure.storage());
    }
  }
}
