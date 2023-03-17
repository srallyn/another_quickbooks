class VendorExpensesException implements Exception {
  final String? message;
  final int statusCode;

  VendorExpensesException({required this.statusCode, this.message});

  @override
  String toString() {
    return "BalanceSheetException: $statusCode - $message";
  }
}
