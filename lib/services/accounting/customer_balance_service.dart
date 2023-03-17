class CustomerBalanceException implements Exception {
  final String? message;
  final int statusCode;

  CustomerBalanceException({required this.statusCode, this.message});

  @override
  String toString() {
    return "CustomerBalanceException: $statusCode - $message";
  }
}
