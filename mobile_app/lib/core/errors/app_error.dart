import 'package:dio/dio.dart';

class AppError {
  final String message;
  final int? statusCode;
  final String? code;

  const AppError({required this.message, this.statusCode, this.code});

  factory AppError.fromDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const AppError(message: 'Connection timed out. Please check your internet connection.');
    }

    if (e.type == DioExceptionType.connectionError) {
      return const AppError(message: 'No internet connection. Please check your network.');
    }

    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    final message = _extractMessage(data) ?? _defaultMessage(statusCode);

    return AppError(message: message, statusCode: statusCode);
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map) {
      return data['error']?['message'] ??
          data['detail'] ??
          data['message'];
    }
    return null;
  }

  static String _defaultMessage(int? code) => switch (code) {
        400 => 'Invalid request. Please check your input.',
        401 => 'Session expired. Please login again.',
        403 => 'You don\'t have permission to do this.',
        404 => 'Resource not found.',
        422 => 'Validation error.',
        429 => 'Too many requests. Please slow down.',
        500 => 'Server error. Please try again later.',
        _ => 'Something went wrong. Please try again.',
      };

  @override
  String toString() => message;
}

typedef AsyncResult<T> = Future<({T? data, AppError? error})>;
