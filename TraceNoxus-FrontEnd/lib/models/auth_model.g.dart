// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
      token: json['access'] as String?,
      refresh: json['refresh'] as String?,
      message: json['message'] as String?,
      error: json['error'] as String?,
      user: json['user'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'access': instance.token,
      'refresh': instance.refresh,
      'message': instance.message,
      'error': instance.error,
      'user': instance.user,
    };

RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
    RegisterRequest(
      email: json['email'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      phoneNumber: json['phone_number'] as String?,
    );

Map<String, dynamic> _$RegisterRequestToJson(RegisterRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'username': instance.username,
      'password': instance.password,
      'phone_number': instance.phoneNumber,
    };

OtpVerificationRequest _$OtpVerificationRequestFromJson(
        Map<String, dynamic> json) =>
    OtpVerificationRequest(
      email: json['email'] as String,
      otp: json['otp'] as String,
    );

Map<String, dynamic> _$OtpVerificationRequestToJson(
        OtpVerificationRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'otp': instance.otp,
    };

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
      email: json['email'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
    };
