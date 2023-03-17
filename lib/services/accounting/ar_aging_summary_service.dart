class ARAgingSummaryException implements Exception {
  final String? message;
  final int statusCode;

  ARAgingSummaryException({required this.statusCode, this.message});

  @override
  String toString() {
    return "ARAgingSummaryException: $statusCode - $message";
  }
}
