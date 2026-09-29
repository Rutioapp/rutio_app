import 'package:flutter/foundation.dart';

import '../../../application/auth/auth_controller.dart';
import '../data/premium_repository.dart';
import '../domain/premium_access.dart';
import '../domain/premium_purchase.dart';

class PremiumController extends ChangeNotifier {
  PremiumController({
    required PremiumRepository repository,
    required AuthController authController,
  })  : _repository = repository,
        _authController = authController {
    _repository.addListener(_onRepositoryChanged);
    _authController.addListener(_onAuthChanged);
  }

  final PremiumRepository _repository;
  final AuthController _authController;
  PremiumPlanKind _selectedPlan = PremiumPlanKind.annual;
  bool _purchaseInProgress = false;
  bool _restoringPurchases = false;
  bool _refreshing = false;
  PremiumPurchaseErrorKind? _error;
  bool _disposed = false;

  PremiumRepository get repository => _repository;
  PremiumAccessState get accessState => _repository.accessState;
  PremiumOffering? get offering => _repository.currentOffering;
  PremiumPlanKind get selectedPlan => _selectedPlan;
  bool get purchaseInProgress => _purchaseInProgress;
  bool get restoringPurchases => _restoringPurchases;
  bool get isRefreshing => _refreshing;
  PremiumPurchaseErrorKind? get error => _error;
  bool get isAuthenticated => _authController.currentUser != null;
  bool get identityReady =>
      isAuthenticated &&
      _repository.hasAuthenticatedIdentity &&
      _repository.boundUserId == _authController.currentUser?.id;
  String? get managementUrl => _repository.managementUrl;

  PremiumSubscriptionPlan? get selectedSubscription =>
      _selectedPlan == PremiumPlanKind.annual
          ? offering?.annual
          : offering?.monthly;

  void selectPlan(PremiumPlanKind plan) {
    if (_selectedPlan == plan) return;
    _selectedPlan = plan;
    _error = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.refresh();
      _ensureAvailableSelection();
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  Future<PremiumPurchaseResult> purchaseSelected() async {
    final package = selectedSubscription;
    if (!identityReady) {
      _error = PremiumPurchaseErrorKind.authenticationRequired;
      notifyListeners();
      return const PremiumPurchaseResult.failed(
        PremiumPurchaseError(PremiumPurchaseErrorKind.authenticationRequired),
      );
    }
    if (package == null) {
      _error = PremiumPurchaseErrorKind.productUnavailable;
      notifyListeners();
      return const PremiumPurchaseResult.failed(
        PremiumPurchaseError(PremiumPurchaseErrorKind.productUnavailable),
      );
    }
    if (_purchaseInProgress) {
      return const PremiumPurchaseResult.pending();
    }
    _purchaseInProgress = true;
    _error = null;
    notifyListeners();
    try {
      final result =
          await _repository.purchasePackage(package.packageIdentifier);
      if (_repository.accessState.isPremium) {
        _error = null;
        return const PremiumPurchaseResult.success();
      }
      if (result.kind == PremiumPurchaseResultKind.failed) {
        _error = result.error?.kind;
      }
      return result;
    } finally {
      _purchaseInProgress = false;
      notifyListeners();
    }
  }

  Future<PremiumPurchaseResult> restorePurchases() async {
    if (!identityReady) {
      _error = PremiumPurchaseErrorKind.authenticationRequired;
      notifyListeners();
      return const PremiumPurchaseResult.failed(
        PremiumPurchaseError(PremiumPurchaseErrorKind.authenticationRequired),
      );
    }
    if (_restoringPurchases) return const PremiumPurchaseResult.pending();
    _restoringPurchases = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _repository.restorePurchases();
      if (result.kind == PremiumPurchaseResultKind.failed) {
        _error = result.error?.kind;
      }
      return result;
    } finally {
      _restoringPurchases = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void _onRepositoryChanged() {
    if (_disposed) return;
    if (_repository.accessState.isPremium) {
      _error = null;
    }
    _ensureAvailableSelection();
    notifyListeners();
  }

  void _ensureAvailableSelection() {
    if (selectedSubscription != null) return;
    if (offering?.annual != null) {
      _selectedPlan = PremiumPlanKind.annual;
    } else if (offering?.monthly != null) {
      _selectedPlan = PremiumPlanKind.monthly;
    }
  }

  void _onAuthChanged() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _repository.removeListener(_onRepositoryChanged);
    _authController.removeListener(_onAuthChanged);
    super.dispose();
  }
}
