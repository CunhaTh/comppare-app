// lib/infra/api_exception.dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;

  ApiException(this.message, {this.body,this.statusCode});

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException [Status $statusCode]: $message';
    }
    return 'ApiException: $message';
  }
}