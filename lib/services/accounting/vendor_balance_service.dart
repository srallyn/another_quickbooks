class VendorBalanceException implements Exception {
  final String? message;
  final int statusCode;

  VendorBalanceException({required this.statusCode, this.message});

  @override
  String toString() {
    return "VendorBalanceException: $statusCode - $message";
  }
}
