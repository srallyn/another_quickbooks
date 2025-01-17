library another_quickbooks;

import 'dart:typed_data';

import 'package:another_quickbooks/quickbook_models.dart';
import 'package:another_quickbooks/services/accounting/account_service.dart';
import 'package:another_quickbooks/services/accounting/bill_service.dart';
import 'package:another_quickbooks/services/accounting/company_info_service.dart';
import 'package:another_quickbooks/services/accounting/customer_service.dart';
import 'package:another_quickbooks/services/accounting/employee_service.dart';
import 'package:another_quickbooks/services/accounting/estimate_service.dart';
import 'package:another_quickbooks/services/accounting/invoice_service.dart';
import 'package:another_quickbooks/services/accounting/item_service.dart';
import 'package:another_quickbooks/services/accounting/payment_service.dart';
import 'package:another_quickbooks/services/accounting/preferences_service.dart';
import 'package:another_quickbooks/services/accounting/profit_loss_service.dart';
import 'package:another_quickbooks/services/accounting/purchase_order_service.dart';
import 'package:another_quickbooks/services/accounting/tax_agency_service.dart';
import 'package:another_quickbooks/services/accounting/transaction_list_service.dart';
import 'package:another_quickbooks/services/accounting/vendor_service.dart';
import 'package:another_quickbooks/services/authentication_service.dart';
import 'package:another_quickbooks/services/discovery_service.dart';
import 'package:another_quickbooks/services/payments/bank_accounts_service.dart';
import 'package:another_quickbooks/services/payments/card_service.dart';
import 'package:another_quickbooks/services/payments/charge_service.dart';
import 'package:another_quickbooks/services/payments/echeck_service.dart';
import 'package:another_quickbooks/services/payments/token_service.dart';

///
/// The QuickBooks client is the main entry point to the Quickbooks API.
/// The client exposes additional APIs grouped in individual clients
/// like the Payments Client and Accounting Client for the Payments
/// and Accounting APIs respectively.
///
class QuickbooksClient {
  final EnvironmentType environmentType;
  final String? applicationId;
  final String clientId;
  final String clientSecret;
  String _url = "quickbooks.api.intuit.com";
  String _paymentsUrl = "sandbox.api.intuit.com";
  String _discoveryUrl =
      "https://developer.api.intuit.com/.well-known/openid_sandbox_configuration";
  late DiscoveryService _discoveryService;
  AuthenticationService? _authenticationService;
  PaymentClient? _paymentClient;
  AccountingClient? _accountingClient;

  QuickbooksClient(
      {required this.applicationId,
        required this.clientId,
        required this.clientSecret,
        this.environmentType = EnvironmentType.Sandbox}) {
    if (environmentType == EnvironmentType.Sandbox) {
      _url = "sandbox-quickbooks.api.intuit.com";
      _discoveryUrl =
      "https://developer.api.intuit.com/.well-known/openid_sandbox_configuration";
      _paymentsUrl = "sandbox.api.intuit.com";
    } else {
      _url = "quickbooks.api.intuit.com";
      _discoveryUrl =
      "https://developer.api.intuit.com/.well-known/openid_configuration";
      _paymentsUrl = "api.intuit.com";
    }
    _discoveryService = DiscoveryService(discoveryUrl: _discoveryUrl);
  }

  /// Initializes the client by fetching the
  /// URLs from the discovery urls
  Future<void> initialize() async {
    // Discover Urls from Quickbooks
    UrlDiscovery discovery = await _discoveryService.initialize();
    // TODO Initialize Services
    _authenticationService = AuthenticationService(
        clientId: clientId,
        clientSecret: clientSecret,
        authorizationEndpoint: discovery.authorization_endpoint,
        tokenEndpoint: discovery.token_endpoint,
        revocationEndpoint: discovery.revocation_endpoint);
    _paymentClient = PaymentClient._(
        baseUrl: _paymentsUrl, authenticationService: _authenticationService!);

    _accountingClient = AccountingClient._(
        baseUrl: _url, authenticationService: _authenticationService!);
  }

  ///
  /// Returns an Authorization URL for presenting the user with
  /// a modal authorization.
  ///
  String getAuthorizationPageUrl(
      {required List<Scope> scopes,
        required String redirectUrl,
        required String state}) {
    if (_authenticationService == null) {
      throw ClientNotInitializedException(message: "Auth Not Ready");
    } else {
      return _authenticationService!.getAuthorizationPageUrl(
          scopes: scopes, redirectUrl: redirectUrl, state: state);
    }
  }

  ///
  /// Gets the Authorization Token from the code.
  ///
  Future<TokenResponse> getAuthToken(
      {required String code,
        required String redirectUrl,
        required String realmId}) async {
    if (_authenticationService == null) {
      throw ClientNotInitializedException(message: "Auth Not Ready");
    } else {
      return _authenticationService!
          .getAuthToken(code: code, redirectUrl: redirectUrl, realmId: realmId);
    }
  }

  ///
  /// Refreshes the authorization token.
  /// Note: If refreshToken is not set it will attempt to use the refresh
  /// token from the last token request it cached if any.
  ///
  Future<TokenResponse> refreshToken({String refreshToken = ""}) async {
    if (_authenticationService == null) {
      throw ClientNotInitializedException(message: "Auth Not Ready");
    } else {
      return _authenticationService!.refreshToken(refreshToken: refreshToken);
    }
  }

  ///
  /// Returns the cached token if available
  ///
  TokenResponse? getCachedToken() {
    if (_authenticationService == null) {
      throw ClientNotInitializedException(message: "Auth Not Ready");
    } else {
      _authenticationService!.getCachedToken();
    }
  }

  ///
  /// Returns the realm ID that was last
  /// used for a token.
  String? getCachedRealmId() {
    if (_authenticationService == null) {
      throw ClientNotInitializedException(message: "Auth Not Ready");
    } else {
      _authenticationService!.getCachedRealmId();
    }
  }

  ///
  /// Sets the cached realmId useful. When refreshing a token
  /// this can be used to also load the realmId
  ///
  /// The cached realmId is used withing another_brother so
  /// we don't constantly have to pass it into the calls.
  ///
  void setCachedRealmId({String? realmId}) {
    if (_authenticationService == null) {
      throw ClientNotInitializedException(message: "Auth Not Ready");
    } else {
      return _authenticationService!.setCachedRealmId(realmId: realmId);
      ;
    }
  }

  ///
  /// Returns the payment client.
  /// The payments client is used to gain access to all the APIs
  /// from QuickBooks Payments
  ///
  PaymentClient getPaymentClient() {
    if (_paymentClient == null) {
      throw ClientNotInitializedException(message: "Payment Not Ready");
    } else {
      return _paymentClient!;
    }
  }

  ///
  /// Returns the accounting client.
  /// The accounting client is used to gain access to all the APIs
  /// from QuickBooks Accounting/Online
  ///
  AccountingClient getAccountingClient() {
    if (_accountingClient == null) {
      throw ClientNotInitializedException(message: "Accounting Not Ready");
    } else {
      return _accountingClient!;
    }
  }

  bool isInitialized() {
    return _authenticationService != null;
  }
}

///
/// The payment client exposes all the Quickbook Payments API
/// Note: This requires a token with the Payments scope.
///
class PaymentClient {
  final String baseUrl;
  final AuthenticationService authenticationService;
  late BankAccountsService _accountsService;
  late CardService _cardService;
  late ChargeService _chargeService;
  late ECheckService _eCheckService;
  late TokenService _tokenService;

  PaymentClient._(
      {required this.baseUrl, required this.authenticationService}) {
    _accountsService = BankAccountsService(
        baseUrl: baseUrl, authenticationService: authenticationService);

    _cardService = CardService(
        baseUrl: baseUrl, authenticationService: authenticationService);

    _chargeService = ChargeService(
        baseUrl: baseUrl, authenticationService: authenticationService);

    _eCheckService = ECheckService(
        baseUrl: baseUrl, authenticationService: authenticationService);

    _tokenService = TokenService(
        baseUrl: baseUrl, authenticationService: authenticationService);
  }

  ///
  /// URL: https://developer.intuit.com/app/developer/qbpayments/docs/api/resources/all-entities/bankaccounts
  /// Creates a bank account
  ///
  Future<BankAccount> createBankAccount({
    required String requestId,
    required String customerId,
    required BankAccount account,
    String? realmId,
    String? authToken,
  }) async {
    return _accountsService.createAccount(
      requestId: requestId,
      customerId: customerId,
      account: account,
      realmId: realmId,
      authToken: authToken,
    );
  }

  ///
  /// This operation allows you to store a new bank account object from a token.
  ///
  Future<BankAccount> createBankAccountFromToken({
    required String requestId,
    required String customerId,
    required String accountToken,
    String? realmId,
    String? authToken,
  }) async {
    return _accountsService.createAccountFromToken(
        requestId: requestId,
        customerId: customerId,
        accountToken: accountToken,
        realmId: realmId,
        authToken: authToken);
  }

  ///
  /// Returns a list of up to ten bank accounts for the company specified
  /// with the id parameter. The accounts are returned in
  /// descending order with most recent accounts first.
  ///
  Future<List<BankAccount>> readAllBankAccounts({
    required String requestId,
    required String customerId,
    String? realmId,
    String? authToken,
  }) async {
    return _accountsService.readAllAccounts(
        requestId: requestId,
        customerId: customerId,
        realmId: realmId,
        authToken: authToken);
  }

  ///
  /// Retrieves a specified BankAccount object.
  ///
  Future<BankAccount> readBankAccount({
    required String bankAccountId,
    required String customerId,
    String? realmId,
    String? authToken,
  }) async {
    return _accountsService.readAccount(
        bankAccountId: bankAccountId,
        customerId: customerId,
        realmId: realmId,
        authToken: authToken);
  }

  ///
  /// Deletes a specified BankAccount object.
  ///
  Future<bool> deleteBankAccount({
    required String requestId,
    required String bankAccountId,
    required String customerId,
    String? realmId,
    String? authToken,
  }) async {
    return _accountsService.deleteAccount(
        requestId: requestId,
        bankAccountId: bankAccountId,
        customerId: customerId,
        realmId: realmId,
        authToken: authToken);
  }

  // Start: Card
  ///
  /// This operation allows you to store a new card object. Note that
  /// this card is only accessible via the Payments API.
  /// It will not appear in QuickBooks Online.
  ///
  Future<Card> createCard({
    required String requestId,
    required String customerId,
    required Card card,
    String? realmId,
    String? authToken,
  }) async {
    return _cardService.createCard(
        requestId: requestId,
        customerId: customerId,
        card: card,
        realmId: requestId,
        authToken: authToken);
  }

  ///
  /// This operation allows you to store a new card object from a token.
  ///
  Future<Card> createCardFromToken({
    required String requestId,
    required String customerId,
    required String cardToken,
    String? realmId,
    String? authToken,
  }) async {
    return _cardService.createCardFromToken(
        requestId: requestId,
        customerId: customerId,
        cardToken: cardToken,
        realmId: requestId,
        authToken: authToken);
  }

  ///
  /// Returns a list of up to ten cards for the company specified
  /// with the id parameter. The cards are returned in descending
  /// order with most recent entry first. This operation cannot
  /// retrieve cards created via the QuickBooks Online interface.
  /// If more than 10 cards are needed, specify the number to be
  /// retrieved using ?count=[number] appended to the end of the query.
  /// For example, /cards?count=100 would retrieve 100 cards.
  ///
  Future<List<Card>> readAllCards({
    required String requestId,
    required String customerId,
    String? realmId,
    String? authToken,
  }) async {
    return _cardService.readAllCards(
        requestId: requestId,
        customerId: customerId,
        realmId: requestId,
        authToken: authToken);
  }

  ///
  /// Retrieves a specified card object.
  /// This operation cannot retrieve cards created via the
  /// QuickBooks Online interface.
  ///
  Future<Card> readCard({
    required String cardId,
    required String customerId,
    String? realmId,
    String? authToken,
  }) async {
    return _cardService.readCard(
        cardId: cardId,
        customerId: customerId,
        realmId: realmId,
        authToken: authToken);
  }

  ///
  /// Deletes a specified card object.
  ///
  Future<bool> deleteCard({
    required String requestId,
    required String cardId,
    required String customerId,
    String? realmId,
    String? authToken,
  }) async {
    return _cardService.deleteCard(
        requestId: requestId,
        cardId: cardId,
        customerId: customerId,
        realmId: realmId,
        authToken: authToken);
  }

  // Start: Charge
  ///
  /// To charge a credit card, you create a new charge object.
  /// If your API key is in development mode, the supplied card
  /// won't actually be charged, though everything else will
  /// occur as if in production mode.
  ///
  Future<Charge> createCharge({
    required String requestId,
    required Charge charge,
    String? realmId,
    String? authToken,
  }) async {
    return _chargeService.createCharge(
        requestId: requestId,
        charge: charge,
        realmId: realmId,
        authToken: authToken);
  }

  ///
  /// Retrieves the details of a charge that has been previously created.
  /// Supply the id as returned in the charges response
  /// body from the previous create operation.
  ///
  Future<Charge> readCharge({
    required String chargeId,
    String? realmId,
    String? authToken,
  }) async {
    return _chargeService.readCharge(
        chargeId: chargeId, realmId: realmId, authToken: authToken);
  }

  ///
  /// Retrieve dull or partial refund.
  ///
  Future<Charge> readRefund({
    required String chargeId,
    required String refundId,
    String? realmId,
    String? authToken,
  }) async {
    return _chargeService.readRefund(
        chargeId: chargeId,
        refundId: refundId,
        realmId: realmId,
        authToken: authToken);
  }

  ///
  /// Full or partial refund an existing charge.
  ///
  Future<Charge> refundCharge({
    required String requestId,
    required String chargeId,
    required String amount,
    String? description,
    PaymentContext? context,
    String? realmId,
    String? authToken,
  }) async {
    return _chargeService.refundCharge(
        requestId: requestId,
        chargeId: chargeId,
        amount: amount,
        description: description,
        context: context,
        realmId: realmId,
        authToken: authToken);
  }

  ///
  /// Capture charge funds
  ///
  Future<Charge> captureCharge({
    required String requestId,
    required String chargeId,
    required String amount,
    String? description,
    PaymentContext? context,
    String? realmId,
    String? authToken,
  }) async {
    return _chargeService.captureCharge(
        requestId: requestId,
        chargeId: chargeId,
        amount: amount,
        description: description,
        context: context,
        realmId: realmId,
        authToken: authToken);
  }

  ///
  /// Processes a void of a charge request that times out.
  /// It cannot be used to void a charge that has already been settled.
  /// Provide the request_id of the original charge as a query parameter.
  ///
  Future<Charge> voidTransaction({
    required String requestId,
    required String chargeRequestId,
    String? realmId,
    String? authToken,
  }) async {
    return _chargeService.voidTransaction(
        requestId: requestId,
        chargeRequestId: chargeRequestId,
        realmId: realmId,
        authToken: authToken);
  }

  // Start: EChecks
  ///
  /// To process an E-check, you create a new debit object.
  ///
  Future<ECheck> createDebit({
    required String requestId,
    required ECheck echeck,
    String? realmId,
    String? authToken,
  }) async {
    return _eCheckService.createDebit(
        requestId: requestId,
        echeck: echeck,
        authToken: authToken,
        realmId: realmId);
  }

  ///
  /// Retrieves the details of an ECheck refund transaction that has
  /// been previously created. The id of a previously created
  /// ECheck refund must be provided.
  ///
  Future<ECheck> readECheckRefund({
    required String echeckId,
    required String refundId,
    String? realmId,
    String? authToken,
  }) async {
    return _eCheckService.readRefund(
        echeckId: echeckId,
        refundId: refundId,
        realmId: realmId,
        authToken: authToken);
  }

  ///
  /// Retrieves the details of an echeck transaction that has been
  /// previously created. Supply the id as returned in the
  /// echecks response body from the previous create operation.
  ///
  Future<ECheck> readECheck({
    required String echeckId,
    String? realmId,
    String? authToken,
  }) async {
    return _eCheckService.readECheck(
        echeckId: echeckId, authToken: authToken, realmId: realmId);
  }

  ///
  /// Full or partial refund an existing ECheck transaction.
  /// Refund requests made on the same day as the associated
  /// debit request may result in the transaction being voided.
  /// Refunds cannot be issued unless the original debit has succeeded
  /// (this process typically takes approximately three business days).
  ///
  Future<ECheck> voidECheck({
    required String requestId,
    required String echeckId,
    String? realmId,
    String? authToken,
  }) async {
    return _eCheckService.voidECheck(
        requestId: requestId,
        echeckId: echeckId,
        realmId: realmId,
        authToken: authToken);
  }

  // Start: Tokens
  ///
  /// Creates a token for the specified card.
  ///
  Future<String> createCardToken({
    required String requestId,
    required Card card,
    String? realmId,
    String? authToken,
  }) async {
    return _tokenService.createCardToken(
        requestId: requestId,
        card: card,
        authToken: authToken,
        realmId: realmId);
  }

  ///
  /// Creates a token for the specified bank account.
  ///
  Future<String> createBankAccountToken({
    required String requestId,
    required BankAccount bankAccount,
    String? realmId,
    String? authToken,
  }) async {
    return _tokenService.createBankAccountToken(
        requestId: requestId,
        bankAccount: bankAccount,
        realmId: realmId,
        authToken: authToken);
  }
}

///
/// The accounting client exposes all the Quickbook Accounting API
/// Note: This requires a token with the Accounting scope.
///
class AccountingClient {
  final String baseUrl;
  final int minorVersion;
  late AccountService _accountsService;
  final AuthenticationService authenticationService;
  late CompanyInfoService _companyInfoService;
  late BillService _billService;
  late CustomerService _customerService;
  late EmployeeService _employeeService;
  late EstimateService _estimateService;
  late InvoiceService _invoiceService;
  late ItemService _itemService;
  late PaymentService _paymentService;
  late PreferencesService _preferencesService;
  late ProfitAndLossService _profitAndLossService;
  late TransactionListService _transactionListService;
  late PurchaseOrderService _purchaseOrderService;
  late TaxAgencyService _taxAgencyService;
  late VendorService _vendorService;

  AccountingClient._(
      {required this.baseUrl,
        required this.authenticationService,
        this.minorVersion = 63}) {
    _accountsService = AccountService(
        baseUrl: baseUrl,
        authenticationService: authenticationService,
        minorVersion: minorVersion);

    _companyInfoService = CompanyInfoService(
        baseUrl: baseUrl,
        authenticationService: authenticationService,
        minorVersion: minorVersion);

    _billService = BillService(
        baseUrl: baseUrl,
        authenticationService: authenticationService,
        minorVersion: minorVersion);

    _customerService = CustomerService(
        baseUrl: baseUrl,
        authenticationService: authenticationService,
        minorVersion: minorVersion);

    _employeeService = EmployeeService(
        baseUrl: baseUrl,
        authenticationService: authenticationService,
        minorVersion: minorVersion);

    _estimateService = EstimateService(
        baseUrl: baseUrl,
        authenticationService: authenticationService,
        minorVersion: minorVersion);

    _invoiceService = InvoiceService(
        baseUrl: baseUrl,
        authenticationService: authenticationService,
        minorVersion: minorVersion);

    _itemService = ItemService(
        baseUrl: baseUrl,
        authenticationService: authenticationService,
        minorVersion: minorVersion);

    _paymentService = PaymentService(
        baseUrl: baseUrl,
        authenticationService: authenticationService,
        minorVersion: minorVersion);

    _preferencesService = PreferencesService(
        baseUrl: baseUrl,
        authenticationService: authenticationService,
        minorVersion: minorVersion);

    _profitAndLossService = ProfitAndLossService(
        baseUrl: baseUrl,
        authenticationService: authenticationService,
        minorVersion: minorVersion);

    _transactionListService = TransactionListService(
        baseUrl: baseUrl,
        authenticationService: authenticationService,
        minorVersion: minorVersion);

    _purchaseOrderService = PurchaseOrderService(
        baseUrl: baseUrl,
        authenticationService: authenticationService,
        minorVersion: minorVersion);

    _taxAgencyService = TaxAgencyService(
        baseUrl: baseUrl,
        authenticationService: authenticationService,
        minorVersion: minorVersion);

    _vendorService = VendorService(
        baseUrl: baseUrl,
        authenticationService: authenticationService,
        minorVersion: minorVersion);
  }

  // Start: Account Service
  ///
  /// Returns the results of the query.
  ///
  Future<List<Account>> queryAccount({
    required String query,
    String? realmId,
    String? authToken,
  }) async {
    return _accountsService.queryAccount(
        query: query, realmId: realmId, authToken: authToken);
  }

  ///
  /// Retrieves the details of an Account object that
  /// has been previously created.
  ///
  Future<Account> readAccount({
    required String accountId,
    String? realmId,
    String? authToken,
  }) async {
    return _accountsService.readAccount(
        accountId: accountId, realmId: realmId, authToken: authToken);
  }

  ///
  /// Creates an account
  /// Name must be unique.
  /// The Account.Name attribute must not contain double quotes (") or colon (:).
  /// The Account.AcctNum attribute must not contain a colon (:).
  ///
  Future<Account> createAccount({
    required Account account,
    String? realmId,
    String? authToken,
  }) async {
    return _accountsService.createAccount(
        account: account, authToken: authToken, realmId: realmId);
  }

  ///
  /// Use this operation to update any of the writable
  /// fields of an existing account object.
  /// The request body must include all writable fields
  /// of the existing object as returned in a read response.
  /// Writable fields omitted from the request body are set to NULL.
  /// The ID of the object to update is specified in the request body.
  ///
  Future<Account> updateAccount({
    required Account account,
    String? realmId,
    String? authToken,
  }) async {
    return _accountsService.updateAccount(
        account: account, realmId: realmId, authToken: authToken);
  }

  // Start CompanyInfo
  ///
  /// Returns the results of the query.
  ///
  Future<List<CompanyInfo>> queryCompanyInfo({
    required String query,
    String? realmId,
    String? authToken,
  }) async {
    return _companyInfoService.queryCompanyInfo(
        query: query, realmId: realmId, authToken: authToken);
  }

  ///
  /// Retrieves the details of the CompanyInfo object.
  ///
  Future<CompanyInfo> readCompanyInfo({
    required String companyId,
    String? realmId,
    String? authToken,
  }) async {
    return _companyInfoService.readCompanyInfo(
        companyId: companyId, realmId: realmId, authToken: authToken);
  }

  ///
  /// Sparse updating provides the ability to update a
  /// subset of properties for a given object; only elements
  /// specified in the request are updated. Missing elements are
  /// left untouched. The ID of the object to update is specified in
  /// the request body.​ Available with minor version 11
  ///
  Future<CompanyInfo> updateCompanyInfo({
    required CompanyInfo companyInfo,
    String? realmId,
    String? authToken,
  }) async {
    return _companyInfoService.updateCompanyInfo(
        companyInfo: companyInfo, realmId: realmId, authToken: authToken);
  }

  // Start: Bill Service
  ///
  /// Returns the results of the query.
  ///
  Future<List<Bill>> queryBill({
    required String query,
    String? realmId,
    String? authToken,
  }) async {
    return _billService.queryBill(
        query: query, realmId: realmId, authToken: authToken);
  }

  ///
  /// Retrieves the details of a bill that has been previously created.
  ///
  Future<Bill> readBill({
    required String billId,
    String? realmId,
    String? authToken,
  }) async {
    return _billService.readBill(
        billId: billId, realmId: realmId, authToken: authToken);
  }

  ///
  /// The minimum elements to create an bill are listed here.
  ///
  Future<Bill> createBill({
    required Bill bill,
    String? realmId,
    String? authToken,
  }) async {
    return _billService.createBill(
        bill: bill, realmId: realmId, authToken: authToken);
  }

  ///
  /// Use this operation to update any of the writable fields of
  /// an existing bill object. The request body must include all
  /// writable fields of the existing object as returned in a read
  /// response. Writable fields omitted from the request body are set
  /// to NULL. The ID of the object to update is specified in the request body.
  ///
  Future<Bill> updateBill({
    required Bill bill,
    String? realmId,
    String? authToken,
  }) async {
    return _billService.updateBill(
        bill: bill, realmId: realmId, authToken: authToken);
  }

  ///
  /// This operation deletes the bill object specified in the request body.
  /// Include a minimum of Bill.Id and Bill.SyncToken in the request body.
  /// You must unlink any linked transactions associated with the bill
  /// object before deleting it.
  ///
  Future<DeleteResponse> deleteBill({
    required Bill bill,
    String? realmId,
    String? authToken,
  }) async {
    return _billService.deleteBill(
        bill: bill, realmId: realmId, authToken: authToken);
  }

  // Start: Customer Service
  ///
  /// Returns the results of the query.
  ///
  Future<List<Customer>> queryCustomer({
    required String query,
    String? realmId,
    String? authToken,
  }) async {
    return _customerService.queryCustomer(
        query: query, realmId: realmId, authToken: authToken);
  }

  ///
  /// Retrieves the details of a Customer object that has
  /// been previously created.
  ///
  Future<Customer> readCustomer({
    required String customerId,
    String? realmId,
    String? authToken,
  }) async {
    return _customerService.readCustomer(
        customerId: customerId, realmId: realmId, authToken: authToken);
  }

  ///
  /// The DisplayName attribute or at least one of Title, GivenName,
  /// MiddleName, FamilyName, or Suffix attributes is required during
  /// object create.
  ///
  Future<Customer> createCustomer({
    required Customer customer,
    String? realmId,
    String? authToken,
  }) async {
    return _customerService.createCustomer(
        customer: customer, realmId: realmId, authToken: authToken);
  }

  ///
  /// Sparse updating provides the ability to update a subset
  /// of properties for a given object; only elements specified
  /// in the request are updated. Missing elements are left untouched.
  /// The ID of the object to update is specified in the request body.​
  ///
  Future<Customer> updateCustomer({
    required Customer customer,
    String? realmId,
    String? authToken,
  }) async {
    return _customerService.updateCustomer(
        customer: customer, realmId: realmId, authToken: authToken);
  }

  // Start: Employee
  ///
  /// Returns the results of the query.
  ///
  Future<List<Employee>> queryEmployee({
    required String query,
    String? realmId,
    String? authToken,
  }) async {
    return _employeeService.queryEmployee(
        query: query, realmId: realmId, authToken: authToken);
  }

  ///
  /// Retrieves the details of a Employee object that has
  /// been previously created.
  ///
  Future<Employee> readEmployee({
    required String employeeId,
    String? realmId,
    String? authToken,
  }) async {
    return _employeeService.readEmployee(
        employeeId: employeeId, realmId: realmId, authToken: authToken);
  }

  ///
  /// Create an employee
  ///
  Future<Employee> createEmployee({
    required Employee employee,
    String? realmId,
    String? authToken,
  }) async {
    return _employeeService.createEmployee(
        employee: employee, realmId: realmId, authToken: authToken);
  }

  ///
  /// Use this operation to update any of the writable fields of an
  /// existing employee object. The request body must include all
  /// writable fields of the existing object as returned in a read
  /// response. Writable fields omitted from the request body are set
  /// to NULL. The ID of the object to update is specified in the request body.
  ///
  Future<Employee> updateEmployee({
    required Employee employee,
    String? realmId,
    String? authToken,
  }) async {
    return _employeeService.updateEmployee(
        employee: employee, realmId: realmId, authToken: authToken);
  }

  // Start: Estimate
  ///
  /// Returns the results of the query.
  ///
  Future<List<Estimate>> queryEstimate({
    required String query,
    String? realmId,
    String? authToken,
  }) async {
    return _estimateService.queryEstimate(
        query: query, realmId: realmId, authToken: authToken);
  }

  ///
  /// Retrieves the details of an estimate that has been previously created.
  ///
  Future<Estimate> readEstimate({
    required String estimateId,
    String? realmId,
    String? authToken,
  }) async {
    return _estimateService.readEstimate(
        estimateId: estimateId, realmId: realmId, authToken: authToken);
  }

  ///
  /// An Estimate must have at least one line that describes an item.
  /// An Estimate must have a reference to a customer.
  /// If shipping address and billing address are not provided,
  /// the address from the referenced Customer object is used.
  ///
  Future<Estimate> createEstimate({
    required Estimate estimate,
    String? realmId,
    String? authToken,
  }) async {
    return _estimateService.createEstimate(
        estimate: estimate, realmId: realmId, authToken: authToken);
  }

  ///
  /// Use this operation to update any of the writable fields of an
  /// existing estimate object. The request body must include
  /// all writable fields of the existing object as returned in a
  /// read response. Writable fields omitted from the request body
  /// are set to NULL. The ID of the object to update is specified
  /// in the request body.
  ///
  Future<Estimate> updateEstimate({
    required Estimate estimate,
    String? realmId,
    String? authToken,
  }) async {
    return _estimateService.updateEstimate(
        estimate: estimate, realmId: realmId, authToken: authToken);
  }

  ///
  /// This operation deletes the estimate object specified
  /// in the request body. Include a minimum of Estimate.Id
  /// and Estimate.SyncToken in the request body.
  ///
  Future<DeleteResponse> deleteEstimate({
    required Estimate estimate,
    String? realmId,
    String? authToken,
  }) async {
    return _estimateService.deleteEstimate(
        estimate: estimate, realmId: realmId, authToken: authToken);
  }

  ///
  /// This resource returns the specified object in the response
  /// body as an Adobe Portable Document Format (PDF) file.
  /// The resulting PDF file is formatted according to custom
  /// form styles in the company settings.
  ///
  Future<Uint8List> getEstimatePdf({
    required String estimateId,
    String? realmId,
    String? authToken,
  }) async {
    return _estimateService.getEstimatePdf(
        estimateId: estimateId, realmId: realmId, authToken: authToken);
  }

  ///
  /// The Estimate.EmailStatus parameter is set to EmailSent.
  /// The Estimate.DeliveryInfo element is populated with sending information.
  /// The Estimate.BillEmail.Address parameter is updated to the
  /// address specified with the value of the sendTo query parameter,
  /// if specified.
  ///
  Future<Estimate> sendEstimate({
    required String estimateId,
    required String emailTo,
    String? realmId,
    String? authToken,
  }) async {
    return _estimateService.sendEstimate(
        estimateId: estimateId,
        emailTo: emailTo,
        realmId: realmId,
        authToken: authToken);
  }

  // Start: Invoice
  ///
  /// Returns the results of the query.
  ///
  Future<List<Invoice>> queryInvoice({
    required String query,
    String? realmId,
    String? authToken,
  }) async {
    return _invoiceService.queryInvoice(
        query: query, realmId: realmId, authToken: authToken);
  }

  ///
  /// Retrieves the details of an invoice that has been previously created.
  ///
  Future<Invoice> readInvoice({
    required String invoiceId,
    String? realmId,
    String? authToken,
  }) async {
    return _invoiceService.readInvoice(
        invoiceId: invoiceId, realmId: realmId, authToken: authToken);
  }

  ///
  /// Have at least one Line a sales item or inline subtotal.
  /// Have a populated CustomerRef element.
  ///
  Future<Invoice> createInvoice({
    required Invoice invoice,
    String? realmId,
    String? authToken,
  }) async {
    return _invoiceService.createInvoice(
        invoice: invoice, realmId: realmId, authToken: authToken);
  }

  ///
  /// Use this operation to update any of the writable fields of an
  /// existing estimate object. The request body must include
  /// all writable fields of the existing object as returned in a
  /// read response. Writable fields omitted from the request body
  /// are set to NULL. The ID of the object to update is specified
  /// in the request body.
  ///
  Future<Invoice> updateInvoice({
    required Invoice invoice,
    String? realmId,
    String? authToken,
  }) async {
    return _invoiceService.updateInvoice(
        invoice: invoice, realmId: realmId, authToken: authToken);
  }

  ///
  /// This operation deletes the invoice object specified in the request body.
  /// Include a minimum of Invoice.Id and Invoice.SyncToken in the
  /// request body. You must unlink any linked transactions associated
  /// with the invoice object before deleting it.
  ///
  Future<DeleteResponse> deleteInvoice({
    required Invoice invoice,
    String? realmId,
    String? authToken,
  }) async {
    return _invoiceService.deleteInvoice(
        invoice: invoice, realmId: realmId, authToken: authToken);
  }

  ///
  /// Use this operation to void an existing invoice object;
  /// include a minimum of Invoice.Id and the current Invoice.SyncToken.
  /// The transaction remains active but all amounts and quantities
  /// are zeroed and the string, Voided, is injected into Invoice.PrivateNote,
  /// prepended to existing text if present.
  ///
  Future<Invoice> voidInvoice({
    required Invoice invoice,
    String? realmId,
    String? authToken,
  }) async {
    return _invoiceService.voidInvoice(
        invoice: invoice, realmId: realmId, authToken: authToken);
  }

  ///
  /// This resource returns the specified object in the
  /// response body as an Adobe Portable Document Format (PDF) file.
  /// The resulting PDF file is formatted according to custom form styles
  /// in the company settings.
  ///
  Future<Uint8List> getInvoicePdf({
    required String invoiceId,
    String? realmId,
    String? authToken,
  }) async {
    return _invoiceService.getInvoicePdf(
        invoiceId: invoiceId, realmId: realmId, authToken: authToken);
  }

  ///
  /// The Invoice.EmailStatus parameter is set to EmailSent.
  /// The Invoice.DeliveryInfo element is populated with sending
  /// information<./li>
  /// The Invoice.BillEmail.Address parameter is updated to the address
  /// specified with the value of the sendTo query parameter, if specified.
  ///
  Future<Invoice> sendInvoice({
    required String invoiceId,
    required String emailTo,
    String? realmId,
    String? authToken,
  }) async {
    return _invoiceService.sendInvoice(
        invoiceId: invoiceId,
        emailTo: emailTo,
        realmId: realmId,
        authToken: authToken);
  }

  // Start: Item
  ///
  /// Returns the results of the query.
  ///
  Future<List<Item>> queryItem({
    required String query,
    String? realmId,
    String? authToken,
  }) async {
    return _itemService.queryItem(
        query: query, realmId: realmId, authToken: authToken);
  }

  ///
  /// Retrieves the details of a item object that has been previously created.
  ///
  Future<Item> readItem({
    required String itemId,
    String? realmId,
    String? authToken,
  }) async {
    return _itemService.readItem(
        itemId: itemId, realmId: realmId, authToken: authToken);
  }

  ///
  /// Creates an item
  ///
  Future<Item> createItem({
    required Item item,
    String? realmId,
    String? authToken,
  }) async {
    return _itemService.createItem(
        item: item, realmId: realmId, authToken: authToken);
  }

  ///
  /// Use this operation to update any of the writable fields of an
  /// existing category object. The ID of the object to update is
  /// specified in the request body.
  ///
  Future<Item> updateItem({
    required Item item,
    String? realmId,
    String? authToken,
  }) async {
    return _itemService.updateItem(
        item: item, realmId: realmId, authToken: authToken);
  }

  // Start: Payment
  ///
  /// Returns the results of the query.
  ///
  Future<List<Payment>> queryPayment({
    required String query,
    String? realmId,
    String? authToken,
  }) async {
    return _paymentService.queryPayment(
        query: query, realmId: realmId, authToken: authToken);
  }

  ///
  /// Retrieves the details of a Payment object that has been
  /// previously created.
  ///
  Future<Payment> readPayment({
    required String paymentId,
    String? realmId,
    String? authToken,
  }) async {
    return _paymentService.readPayment(
        paymentId: paymentId, realmId: realmId, authToken: authToken);
  }

  ///
  /// Creates a payment
  ///
  Future<Payment> createPayment({
    required Payment payment,
    String? realmId,
    String? authToken,
  }) async {
    return _paymentService.createPayment(
        payment: payment, realmId: realmId, authToken: authToken);
  }

  ///
  /// Use this operation to update any of the writable fields
  /// of an existing Payment object. The request body must
  /// include all writable fields of the existing object as
  /// returned in a read response. Writable fields omitted
  /// from the request body are set to NULL. The ID of the
  /// object to update is specified in the request body.
  ///
  Future<Payment> updatePayment({
    required Payment payment,
    String? realmId,
    String? authToken,
  }) async {
    return _paymentService.updatePayment(
        payment: payment, realmId: realmId, authToken: authToken);
  }

  ///
  /// This operation deletes the Payment object specified in the request body.
  /// Include a minimum of Payment.Id and Payment.SyncToken in the request body.
  ///
  Future<DeleteResponse> deletePayment({
    required Payment payment,
    String? realmId,
    String? authToken,
  }) async {
    return _paymentService.deletePayment(
        payment: payment, realmId: realmId, authToken: authToken);
  }

  ///
  /// Use a sparse update operation with include=void to void an
  /// existing Payment object; include a minimum of Payment.Id
  /// and Payment.SyncToken.The transaction remains active but
  /// all amounts and quantities are zeroed and the string, Voided,
  /// is injected into Payment.PrivateNote, prepended to existing text
  /// if present. If funds for the payment have been deposited,
  /// you must delete the associated deposit object before voiding
  /// the payment object.
  ///
  Future<Payment> voidPayment({
    required Payment payment,
    String? realmId,
    String? authToken,
  }) async {
    return _paymentService.voidPayment(
        payment: payment, realmId: realmId, authToken: authToken);
  }

  ///
  /// This resource returns the specified object in the
  /// response body as an Adobe Portable Document Format (PDF) file.
  /// The resulting PDF file is formatted according to custom form
  /// styles in the company settings.
  ///
  Future<Uint8List> getPaymentPdf({
    required String paymentId,
    String? realmId,
    String? authToken,
  }) async {
    return _paymentService.getPaymentPdf(
        paymentId: paymentId, realmId: realmId, authToken: authToken);
  }

  ///
  /// Sends a payment to the specified email.
  ///
  Future<Payment> sendPayment({
    required String paymentId,
    required String emailTo,
    String? realmId,
    String? authToken,
  }) async {
    return _paymentService.sendPayment(
        paymentId: paymentId,
        emailTo: emailTo,
        realmId: realmId,
        authToken: authToken);
  }

  // Preferences
  ///
  /// Returns the results of the query.
  ///
  Future<List<Preferences>> queryPreferences({
    required String query,
    String? realmId,
    String? authToken,
  }) async {
    return _preferencesService.queryPreferences(
        query: query, realmId: realmId, authToken: authToken);
  }

  ///
  /// Retrieves the Preferences details for the specified company.
  ///
  Future<Preferences> readPreferences({
    String? realmId,
    String? authToken,
  }) async {
    return _preferencesService.readPreferences(
        realmId: realmId, authToken: authToken);
  }

  ///
  /// Use this operation to update any of the writable preference fields.
  /// The request body must include all writable fields of the
  /// existing object as returned in a read response.
  /// Writable fields omitted from the request body are set to
  /// NULL or reverted to a default value. The ID of the object
  /// to update is specified in the request body.
  ///
  Future<Preferences> updatePreferences({
    required Preferences preferences,
    String? realmId,
    String? authToken,
  }) async {
    return _preferencesService.updatePreferences(
        preferences: preferences, realmId: realmId, authToken: authToken);
  }

  // Profit And Loss
  ///
  /// Returns the Profit and Loss report for the query
  ///
  Future<ProfitAndLoss> queryProfitAndLossReport({
    required ProfitAndLossQuery query,
    String? realmId,
    String? authToken,
  }) async {
    return _profitAndLossService.queryReport(
        query: query, realmId: realmId, authToken: authToken);
  }

  // Transaction List
  ///
  /// Returns the Transaction List report for the query
  ///
  Future<TransactionList> queryTransactionListReport({
    required TransactionListQuery query,
    String? realmId,
    String? authToken,
  }) async {
    return _transactionListService.queryReport(
        query: query, realmId: realmId, authToken: authToken);
  }

  // Start: Tax Agency
  ///
  /// Returns the results of the query.
  ///
  Future<List<TaxAgency>> queryTaxAgency({
    required String query,
    String? realmId,
    String? authToken,
  }) async {
    return _taxAgencyService.queryTaxAgency(
        query: query, realmId: realmId, authToken: authToken);
  }

  ///
  /// Retrieves the details of a TaxAgency object that has
  /// been previously created.
  ///
  Future<TaxAgency> readTaxAgency({
    required String taxAgencyId,
    String? realmId,
    String? authToken,
  }) async {
    return _taxAgencyService.readTaxAgency(
        taxAgencyId: taxAgencyId, realmId: realmId, authToken: authToken);
  }

  ///
  /// A TaxAgency object must have a DisplayName attribute.
  ///
  Future<TaxAgency> createTaxAgency({
    required TaxAgency agency,
    String? realmId,
    String? authToken,
  }) async {
    return _taxAgencyService.createTaxAgency(
        agency: agency, realmId: realmId, authToken: authToken);
  }

  // Start: Purchase Order Service
  ///
  /// Returns the results of the query.
  ///
  Future<List<PurchaseOrder>> queryPurchaseOrder({
    required String query,
    String? realmId,
    String? authToken,
  }) async {
    return _purchaseOrderService.queryPurchaseOrder(
        query: query, realmId: realmId, authToken: authToken);
  }

  ///
  /// Retrieves the details of a purchaseOrder that has been previously created.
  ///
  Future<PurchaseOrder> readPurchaseOrder({
    required String purchaseOrderId,
    String? realmId,
    String? authToken,
  }) async {
    return _purchaseOrderService.readPurchaseOrder(
        purchaseOrderId: purchaseOrderId,
        realmId: realmId,
        authToken: authToken);
  }

  ///
  /// The minimum elements to create an purchaseOrder are listed here.
  ///
  Future<PurchaseOrder> createPurchaseOrder({
    required PurchaseOrder purchaseOrder,
    String? realmId,
    String? authToken,
  }) async {
    return _purchaseOrderService.createPurchaseOrder(
        purchaseOrder: purchaseOrder, realmId: realmId, authToken: authToken);
  }

  ///
  /// Use this operation to update any of the writable fields of
  /// an existing purchaseOrder object. The request body must include all
  /// writable fields of the existing object as returned in a read
  /// response. Writable fields omitted from the request body are set
  /// to NULL. The ID of the object to update is specified in the request body.
  ///
  Future<PurchaseOrder> updatePurchaseOrder({
    required PurchaseOrder purchaseOrder,
    String? realmId,
    String? authToken,
  }) async {
    return _purchaseOrderService.updatePurchaseOrder(
        purchaseOrder: purchaseOrder, realmId: realmId, authToken: authToken);
  }

  ///
  /// This operation deletes the purchaseOrder object specified in the request body.
  /// Include a minimum of PurchaseOrder.Id and PurchaseOrder.SyncToken in the request body.
  /// You must unlink any linked transactions associated with the purchaseOrder
  /// object before deleting it.
  ///
  Future<DeleteResponse> deletePurchaseOrder({
    required PurchaseOrder purchaseOrder,
    String? realmId,
    String? authToken,
  }) async {
    return _purchaseOrderService.deletePurchaseOrder(
        purchaseOrder: purchaseOrder, realmId: realmId, authToken: authToken);
  }

  // Start: Vendor
  ///
  /// Returns the results of the query.
  ///
  Future<List<Vendor>> queryVendor({
    required String query,
    String? realmId,
    String? authToken,
  }) async {
    return _vendorService.queryVendor(
        query: query, realmId: realmId, authToken: authToken);
  }

  ///
  /// Retrieves the details of a Vendor object that has been previously created.
  ///
  Future<Vendor> readVendor({
    required String vendorId,
    String? realmId,
    String? authToken,
  }) async {
    return _vendorService.readVendor(
        vendorId: vendorId, realmId: realmId, authToken: authToken);
  }

  ///
  /// Either the DisplayName attribute or at least one of Title, GivenName,
  /// MiddleName, FamilyName, or Suffix attributes are required during create.
  ///
  Future<Vendor> createVendor({
    required Vendor vendor,
    String? realmId,
    String? authToken,
  }) async {
    return _vendorService.createVendor(
        vendor: vendor, realmId: realmId, authToken: authToken);
  }

  ///
  /// Use this operation to update any of the writable
  /// fields of an existing vendor object. The request
  /// body must include all writable fields of the existing
  /// object as returned in a read response. Writable fields
  /// omitted from the request body are set to NULL. The ID of
  /// the object to update is specified in the request body.Add
  /// the query parameter, include=updateaccountontxns&minorversion=5,
  /// to the endpoint to automatically update the AP account on historical
  /// transactions (from soft close date forward) for this vendor with that
  /// defined by the APAccountRef attribute in the Vendor object. Updates
  /// on soft closed transacitons associated will fail.
  ///
  Future<Vendor> updateVendor({
    required Vendor vendor,
    String? realmId,
    String? authToken,
  }) async {
    return _vendorService.updateVendor(
        vendor: vendor, realmId: realmId, authToken: authToken);
  }
}

enum EnvironmentType {
  Sandbox,
  Production,
}

class ClientNotInitializedException implements Exception {
  final String message;

  ClientNotInitializedException({required this.message});
}
