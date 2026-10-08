import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  late final Dio _dio;
  
  // Use 10.0.2.2 for Android Emulator, localhost for iOS/Web/Desktop
  // Production server URL (Port 80)
  static const String serverBaseUrl = 'http://109.199.99.156/api';

  static String get defaultBaseUrl {
    // Points directly to the deployed backend server
    return serverBaseUrl;
  }

  ApiClient({String? baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? defaultBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    // Request interceptor to automatically add Sanctum token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Global error handling can be done here
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;
}
