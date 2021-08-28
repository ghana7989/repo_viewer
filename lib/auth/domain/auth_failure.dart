import 'package:freezed_annotation/freezed_annotation.dart';

part "auth_failure.freezed.dart";

@freezed
class AuthFailure with _$AuthFailure {
  const AuthFailure._();
  // This is a named constructor in AuthFailure Class
  // Here server is a constructor which accepts an optional parameter message
  const factory AuthFailure.server([String? message]) = _Server;
  const factory AuthFailure.storage() = _Storage;
}
