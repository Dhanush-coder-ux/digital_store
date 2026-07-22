// lib/core/models/api_error_model.dart
//
// Generated from OpenAPI HTTPValidationError and ValidationError schemas.
// Used for parsing FastAPI 422 validation error responses.
//

class HttpValidationError {
  final List<ApiValidationError> detail;

  const HttpValidationError({this.detail = const []});

  factory HttpValidationError.fromJson(Map<String, dynamic> json) {
    final rawDetail = json['detail'];
    List<ApiValidationError> errors = [];
    if (rawDetail is List) {
      errors = rawDetail
          .whereType<Map<String, dynamic>>()
          .map((e) => ApiValidationError.fromJson(e))
          .toList();
    }
    return HttpValidationError(detail: errors);
  }

  /// Human-readable error summary.
  String get summary {
    if (detail.isEmpty) return 'Validation error';
    return detail.map((e) => '${e.fieldName}: ${e.msg}').join('\n');
  }
}

class ApiValidationError {
  /// Location path — e.g. ["body", "name"]
  final List<dynamic> loc;
  final String msg;
  final String type;
  final dynamic input;
  final Map<String, dynamic>? ctx;

  const ApiValidationError({
    this.loc = const [],
    required this.msg,
    required this.type,
    this.input,
    this.ctx,
  });

  factory ApiValidationError.fromJson(Map<String, dynamic> json) {
    return ApiValidationError(
      loc: json['loc'] is List ? json['loc'] as List : [],
      msg: json['msg']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      input: json['input'],
      ctx: json['ctx'] is Map<String, dynamic>
          ? json['ctx'] as Map<String, dynamic>
          : null,
    );
  }

  /// The field name (last element of loc, skipping 'body').
  String get fieldName {
    final meaningful = loc.where((e) => e.toString() != 'body');
    return meaningful.isNotEmpty ? meaningful.last.toString() : 'unknown';
  }
}
