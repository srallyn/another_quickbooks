class BalanceSheetException implements Exception {
  final String? message;
  final int statusCode;

  BalanceSheetException({required this.statusCode, this.message});

  @override
  String toString() {
    return "BalanceSheetException: $statusCode - $message";
  }
}

