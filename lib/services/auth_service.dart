// lib/services/auth_service.dart
//
// Stripped-down auth service — authentication has been removed from this app.
// Only the shared exception classes remain, as they are imported by other services.
//

/// Thrown when an API call fails due to network / server errors.
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}

/// Kept for backward compatibility — same semantics as ApiException.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}
