class APAgingSummaryException implements Exception {
  final String? message;
  final int statusCode;

  APAgingSummaryException({required this.statusCode, this.message});

  @override
  String toString() {
    return "APAgingSummaryException: $statusCode - $message";
  }
}
