import 'package:json_annotation/json_annotation.dart';

part 'auth_model.g.dart';

@JsonSerializable()
class AuthResponse {
  @JsonKey(name: 'access')
  final String? token;
  final String? refresh;
  final String? message;
  final String? error;
  final Map<String, dynamic>? user;

  AuthResponse({this.token, this.refresh, this.message, this.error, this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable()
class RegisterRequest {
  final String email;
  final String username;
  final String password;

  RegisterRequest({
    required this.email,
    required this.username,
    required this.password,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) => _$RegisterRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}

@JsonSerializable()
class OtpVerificationRequest {
  final String email;
  final String otp;

  OtpVerificationRequest({
    required this.email,
    required this.otp,
  });

  factory OtpVerificationRequest.fromJson(Map<String, dynamic> json) => _$OtpVerificationRequestFromJson(json);
  Map<String, dynamic> toJson() => _$OtpVerificationRequestToJson(this);
}

@JsonSerializable()
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) => _$LoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
} 