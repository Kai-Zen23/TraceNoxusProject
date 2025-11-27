class AppConstants {
  //static const String baseUrl = 'http://192.168.1.24:8000';
  //static const String baseUrl = 'https://tracenoxus.onrender.com';
  //static const String baseUrl = 'http://10.0.2.2:8000'; // Local Android Emulator
  static const String baseUrl = 'http://10.0.0.105:8000'; // Local IP Address
  
  // Routes
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String homeRoute = '/home';
  
  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  
  // Error Messages
  static const String loginError = 'Failed to login';
  static const String registerError = 'Failed to register';
  static const String noTokenError = 'No token found';
  static const String profileError = 'Failed to get profile';
}