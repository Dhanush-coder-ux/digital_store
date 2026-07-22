// lib/core/network/api_exceptions.dart
//
// Typed exception hierarchy for all API error handling.
// Maps HTTP status codes to specific exception types.
//

/// Base API exception — all network/API errors extend this.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic body;

  const ApiException(this.message, {this.statusCode, this.body});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// 401 — Access token invalid or expired. Triggers token refresh.
class UnauthorizedException extends ApiException {
  const UnauthorizedException([String message = 'Unauthorized. Please log in again.'])
      : super(message, statusCode: 401);
}

/// 403 — Access forbidden for this service/role.
class ForbiddenException extends ApiException {
  const ForbiddenException([String message = 'Access forbidden.'])
      : super(message, statusCode: 403);
}

/// 404 — Resource not found.
class NotFoundException extends ApiException {
  const NotFoundException([String message = 'Resource not found.'])
      : super(message, statusCode: 404);
}

/// 422 — Validation error with field-level details from FastAPI.
class ValidationException extends ApiException {
  final List<ValidationDetail> errors;

  const ValidationException({
    String message = 'Validation error.',
    this.errors = const [],
  }) : super(message, statusCode: 422);

  @override
  String toString() {
    if (errors.isEmpty) return 'ValidationException: $message';
    final details = errors.map((e) => '  ${e.field}: ${e.message}').join('\n');
    return 'ValidationException:\n$details';
  }
}

/// Individual field validation error from FastAPI's HTTPValidationError.
class ValidationDetail {
  final String field;
  final String message;
  final String type;

  const ValidationDetail({
    required this.field,
    required this.message,
    this.type = '',
  });

  factory ValidationDetail.fromJson(Map<String, dynamic> json) {
    final loc = json['loc'];
    String field = '';
    if (loc is List && loc.isNotEmpty) {
      // Skip 'body' prefix, take actual field name
      field = loc.where((e) => e != 'body').map((e) => e.toString()).join('.');
      if (field.isEmpty) field = loc.last.toString();
    }
    return ValidationDetail(
      field: field,
      message: json['msg']?.toString() ?? 'Invalid value',
      type: json['type']?.toString() ?? '',
    );
  }
}

/// 500 — Internal server error.
class ServerException extends ApiException {
  const ServerException([String message = 'Server error. Please try again later.'])
      : super(message, statusCode: 500);
}

/// Request timed out.
class ApiTimeoutException extends ApiException {
  const ApiTimeoutException([String message = 'Request timed out. Check your connection.'])
      : super(message);
}

/// No internet connection detected.
class NoInternetException extends ApiException {
  const NoInternetException([String message = 'No internet connection.'])
      : super(message);
}

/// Token has expired — distinct from general 401 for auto-refresh logic.
class TokenExpiredException extends UnauthorizedException {
  const TokenExpiredException([String message = 'Session expired. Refreshing...'])
      : super(message);
}
