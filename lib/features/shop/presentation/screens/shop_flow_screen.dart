import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rutio/features/shop/application/shop_cosmetics_controller.dart';
import 'package:rutio/features/shop/application/shop_controller.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/data/shop_local_repository.dart';
import 'package:rutio/features/shop/domain/models/mystery_box_opening_transaction.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/presentation/models/shop_flow_snapshot.dart';
import 'package:rutio/features/shop/presentation/screens/shop_cosmetic_detail_container.dart';
import 'package:rutio/features/shop/presentation/screens/shop_backpack_screen.dart';
import 'package:rutio/features/shop/presentation/screens/shop_collections_screen.dart';
import 'package:rutio/features/shop/presentation/screens/shop_cosmetics_screen.dart';
import 'package:rutio/features/shop/presentation/screens/shop_customization_screen.dart';
import 'package:rutio/features/shop/presentation/screens/mystery_box_opening_screen.dart';
import 'package:rutio/features/shop/presentation/screens/shop_home_screen.dart';
import 'package:rutio/features/shop/presentation/screens/shop_item_detail_container.dart';
import 'package:rutio/features/shop/presentation/screens/shop_utilities_screen.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_empty_state.dart';
import 'package:rutio/screens/diary_v2/diary_v2_screen.dart';
import 'package:rutio/screens/habit_archived_screen.dart';
import 'package:rutio/screens/habit_monthly_screen.dart';
import 'package:rutio/screens/habit_weekly_screen.dart';
import 'package:rutio/screens/home/home_screen.dart';
import 'package:rutio/screens/profile/profile_screen.dart';
import 'package:rutio/features/statistics/presentation/v3/screens/statistics_v3_screen.dart';
import 'package:rutio/widgets/app_view_drawer.dart';
import 'package:rutio/features/habits/domain/models/streak_recover_operation_result.dart';
import 'package:rutio/features/habits/domain/models/streak_shield_operation_result.dart';

void _navReplace(BuildContext context, Widget screen) {
  final scaffold = Scaffold.maybeOf(context);
  if (scaffold != null && scaffold.isDrawerOpen) {
    Navigator.of(context).pop();
  }

  Navigator.of(context).pushReplacement(
    CupertinoPageRoute<void>(builder: (_) => screen),
  );
}

enum _ShopFlowPage {
  home,
  cosmetics,
  utilities,
  collections,
  backpack,
  customization,
  detail,
}

class ShopFlowScreen extends StatefulWidget {
  const ShopFlowScreen({
    super.key,
    required this.controller,
    required this.cosmeticsController,
    this.shopRepository,
  });

  final ShopController controller;
  final ShopCosmeticsController cosmeticsController;
  final ShopLocalRepository? shopRepository;

  @override
  State<ShopFlowScreen> createState() => _ShopFlowScreenState();
}

class _ShopFlowScreenState extends State<ShopFlowScreen> {
  final List<_ShopFlowPage> _stack = <_ShopFlowPage>[_ShopFlowPage.home];

  ShopFlowSnapshot? _snapshot;
  ShopCloudEconomyStatus? _economyStatus;
  String? _selectedItemId;
  bool _loading = true;
  bool _isMysteryBoxRouteVisible = false;
  bool _isStreakUtilityFlowVisible = false;

  @override
  void initState() {
    super.initState();
    _reloadSnapshot();
  }

  Future<void> _reloadSnapshot() async {
    setState(() {
      _loading = true;
    });

    final snapshot = await _loadSnapshot();
    if (!mounted) return;

    setState(() {
      _snapshot = snapshot;
      _economyStatus = widget.controller.economyStatus;
      _loading = false;
    });
  }

  Future<ShopFlowSnapshot?> _loadSnapshot() async {
    if (widget.controller.isCloudEconomyEnabled) {
      await widget.controller.resolvePendingPurchasesForCurrentUser();
      await widget.controller.hydrateVisibleEconomy();
      if (!_isRenderableEconomyStatus(widget.controller.economyStatus)) {
        return null;
      }
    }

    final int walletCoins = widget.controller.visibleCoinBalance ??
        widget.controller.getWalletCoins();
    final shopState = await widget.controller.getVisibleShopState();
    final cosmeticsState = await widget.cosmeticsController.getState();
    final activeUtilityEffects =
        await widget.controller.getActiveUtilityEffects();
    final pendingMysteryBoxOpenings =
        await widget.controller.getPendingMysteryBoxOpenings();
    return ShopFlowSnapshot.fromStore(
      walletCoins: walletCoins,
      shopState: shopState,
      cosmeticsState: cosmeticsState,
      activeUtilityEffects: activeUtilityEffects,
      pendingMysteryBoxOpenings: pendingMysteryBoxOpenings,
    );
  }

  bool _isRenderableEconomyStatus(ShopCloudEconomyStatus status) {
    return status == ShopCloudEconomyStatus.disabled ||
        status == ShopCloudEconomyStatus.ready ||
        status == ShopCloudEconomyStatus.stale;
  }

  void _pushPage(_ShopFlowPage page) {
    setState(() {
      _stack.add(page);
    });
  }

  void _replaceTopPage(_ShopFlowPage page) {
    setState(() {
      if (_stack.isNotEmpty) {
        _stack.removeLast();
      }
      _stack.add(page);
    });
  }

  void _popPage() {
    if (_stack.length <= 1) {
      Navigator.of(context).maybePop();
      return;
    }

    final poppedPage = _stack.last;
    setState(() {
      _stack.removeLast();
      if (_stack.last != _ShopFlowPage.detail) {
        _selectedItemId = null;
      }
    });

    if (poppedPage == _ShopFlowPage.cosmetics ||
        poppedPage == _ShopFlowPage.customization) {
      _reloadSnapshot();
    }
  }

  void _openCosmetics() => _pushPage(_ShopFlowPage.cosmetics);
  void _openUtilities() => _pushPage(_ShopFlowPage.utilities);
  void _openBackpack() => _pushPage(_ShopFlowPage.backpack);
  void _openCustomization() => _pushPage(_ShopFlowPage.customization);

  void _openDetail(String itemId) {
    setState(() {
      _selectedItemId = itemId;
      _stack.add(_ShopFlowPage.detail);
    });
  }

  void _openCollection(String collectionId) {
    _showSnack('Coleccion $collectionId disponible pronto');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.fixed,
        backgroundColor: ShopUiTokens.textPrimary,
      ),
    );
  }

  Future<void> _handleUsePressed(String itemId) async {
    final item = ShopCatalog.getItemById(itemId);
    if (item == null) {
      _showSnack('No pudimos encontrar la utilidad');
      return;
    }

    if (item.type == ShopItemType.mysteryBox) {
      final pendingMysteryBox =
          _snapshot != null && _snapshot!.pendingMysteryBoxOpenings.isNotEmpty
              ? _snapshot!.pendingMysteryBoxOpenings.first
              : null;
      if (pendingMysteryBox != null) {
        await _showMysteryBoxOpening(pendingMysteryBox);
      } else {
        await _openMysteryBox();
      }
      return;
    }

    if (item.type == ShopItemType.streakShield) {
      await _activateStreakShield(itemId);
      return;
    }

    if (item.type == ShopItemType.streakRecover) {
      await _recoverStreak(itemId);
      return;
    }

    if (item.type != ShopItemType.xpBoost &&
        item.type != ShopItemType.coinBoost) {
      _showSnack('Disponible proximamente');
      return;
    }

    final result = await widget.controller.activateBoost(itemId);
    if (!mounted) return;

    await _reloadSnapshot();
    switch (result.status) {
      case ShopControllerStatus.success:
        _showSnack('Boost activado');
        break;
      case ShopControllerStatus.backpackItemNotFound:
        _showSnack('No quedan unidades en la mochila');
        break;
      case ShopControllerStatus.utilityAlreadyActive:
        _showSnack('Ya tienes un boost activo de ese tipo');
        break;
      case ShopControllerStatus.utilityActivationInProgress:
        _showSnack('Ese boost ya se esta activando');
        break;
      case ShopControllerStatus.invalidItemType:
        _showSnack('Disponible proximamente');
        break;
      case ShopControllerStatus.itemNotFound:
        _showSnack('No pudimos encontrar la utilidad');
        break;
      case ShopControllerStatus.unavailableState:
        _showSnack('No pudimos actualizar tu estado');
        break;
      case ShopControllerStatus.cloudPurchaseInProgress:
        _showSnack('Compra en curso');
        break;
      case ShopControllerStatus.cloudPurchasePending:
        _showSnack('Compra en curso');
        break;
      case ShopControllerStatus.cloudPurchaseFailed:
        _showSnack('No se ha podido activar');
        break;
      case ShopControllerStatus.insufficientCoins:
      case ShopControllerStatus.alreadyOwned:
      case ShopControllerStatus.itemNotOwned:
        _showSnack('No se ha podido activar');
        break;
    }
  }

  Future<void> _handleCosmeticsEquipPressed(String itemId) async {
    final result = await widget.cosmeticsController.equipAsset(itemId);
    if (!mounted) return;
    if (!result.isSuccess) {
      _showSnack('No se ha podido equipar el cosmetico');
    }
  }

  Future<void> _handlePurchaseCompleted(ShopControllerResult result) async {
    if (!mounted) return;

    await _reloadSnapshot();
    final ShopItem? item = result.item;
    if (item != null &&
        result.isSuccess &&
        item.category == ShopItemCategory.utility) {
      _replaceTopPage(_ShopFlowPage.backpack);
    }
  }

  Future<void> _handleEquipCompleted(ShopControllerResult result) async {
    if (!mounted) return;
    await _reloadSnapshot();
  }

  Future<void> _openMysteryBox() async {
    if (_isMysteryBoxRouteVisible) return;
    HapticFeedback.lightImpact();
    await _showMysteryBoxOpening();
  }

  Future<void> _showMysteryBoxOpening([
    MysteryBoxOpeningTransaction? transaction,
  ]) async {
    if (_isMysteryBoxRouteVisible) {
      return;
    }

    _isMysteryBoxRouteVisible = true;

    try {
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        CupertinoPageRoute<void>(
          builder: (BuildContext routeContext) {
            return MysteryBoxOpeningScreen(
              transaction: transaction,
              onClose: () => Navigator.of(routeContext).pop(),
              onBoxTapped: () {},
              onOpenRequested: transaction == null
                  ? () => widget.controller.openMysteryBox()
                  : null,
              onMarkPresented:
                  (MysteryBoxOpeningTransaction transaction) async =>
                      (await widget.controller.presentMysteryBoxResult(
                transaction.id,
              ))
                          .isSuccess,
            );
          },
        ),
      );

      if (!mounted) return;
      await _reloadSnapshot();
    } finally {
      _isMysteryBoxRouteVisible = false;
    }
  }

  Future<void> _activateStreakShield(String itemId) async {
    if (_isStreakUtilityFlowVisible) return;
    if (!mounted) return;

    setState(() {
      _isStreakUtilityFlowVisible = true;
    });

    try {
      final activeHabits = widget.controller.getActiveHabits();
      final eligibleHabits = activeHabits
          .where(
            (habit) =>
                !_isArchivedHabit(habit) &&
                widget.controller.getActiveStreakShieldForHabit(
                      _habitId(habit),
                    ) ==
                    null,
          )
          .toList(growable: false);
      if (eligibleHabits.isEmpty) {
        _showSnack('No tienes hábitos elegibles para activar un escudo');
        return;
      }

      final selectedHabitId = await _showStreakHabitPicker(
        title: 'Activa un escudo',
        subtitle: 'Elige el hábito que quieres proteger',
        habits: eligibleHabits,
      );
      if (selectedHabitId == null || !mounted) return;

      final result = await widget.controller.activateStreakShield(
        habitId: selectedHabitId,
        operationId: _streakOperationId('shield', selectedHabitId),
      );
      if (!mounted) return;
      await _reloadSnapshot();
      _showSnack(
        result.isSuccess
            ? 'Escudo activado'
            : result.status == StreakShieldOperationStatus.noInventory
                ? 'No quedan unidades en la mochila'
                : 'No se ha podido activar el escudo',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isStreakUtilityFlowVisible = false;
        });
      }
    }
  }

  Future<void> _recoverStreak(String itemId) async {
    if (_isStreakUtilityFlowVisible) return;
    if (!mounted) return;

    setState(() {
      _isStreakUtilityFlowVisible = true;
    });

    try {
      final recoverableBreaks = widget.controller
          .getRecoverableStreakBreaks()
          .where(
            (breakRecord) =>
                breakRecord.isRecoverable && !breakRecord.shieldProtected,
          )
          .toList(growable: false);
      if (recoverableBreaks.isEmpty) {
        _showSnack('No hay rachas recuperables ahora mismo');
        return;
      }

      final activeHabits = widget.controller.getActiveHabits();
      final selectedBreakId = await _showStreakBreakPicker(
        title: 'Recupera tu racha',
        subtitle: 'Elige la rotura que quieres restaurar',
        breaks: recoverableBreaks,
        habitTitleForId: (habitId) => _habitTitleFromHabitId(
          activeHabits,
          habitId,
        ),
      );
      if (selectedBreakId == null || !mounted) return;

      final result = await widget.controller.recoverStreakBreak(
        breakId: selectedBreakId,
        operationId: _streakOperationId('recover', selectedBreakId),
      );
      if (!mounted) return;
      await _reloadSnapshot();
      _showSnack(
        result.isSuccess
            ? 'Racha recuperada'
            : result.status == StreakRecoverOperationStatus.noInventory
                ? 'No quedan unidades en la mochila'
                : 'No se ha podido recuperar la racha',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isStreakUtilityFlowVisible = false;
        });
      }
    }
  }

  Future<String?> _showStreakHabitPicker({
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> habits,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        return _StreakSelectionSheet(
          title: title,
          subtitle: subtitle,
          items: habits
              .map((habit) {
                final habitId = _habitId(habit);
                return _SelectableSheetItem(
                  id: habitId,
                  title: _habitTitle(habit),
                  subtitle: _habitSubtitle(habit),
                  trailing: widget.controller
                              .getActiveStreakShieldForHabit(habitId) ==
                          null
                      ? 'Disponible'
                      : 'Bloqueado',
                );
              })
              .where((item) => item.id.isNotEmpty)
              .toList(growable: false),
          onSelected: (id) => Navigator.of(bottomSheetContext).pop(id),
          onCancel: () => Navigator.of(bottomSheetContext).pop(),
        );
      },
    );
  }

  Future<String?> _showStreakBreakPicker({
    required String title,
    required String subtitle,
    required List<dynamic> breaks,
    required String Function(String habitId) habitTitleForId,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        return _StreakSelectionSheet(
          title: title,
          subtitle: subtitle,
          items: breaks
              .map(
                (breakRecord) => _SelectableSheetItem(
                  id: breakRecord.id.toString(),
                  title: habitTitleForId(breakRecord.habitId.toString()),
                  subtitle: 'Se puede recuperar hasta 48 horas después',
                  trailing: breakRecord.missedOccurrenceDateKey.toString(),
                ),
              )
              .toList(growable: false),
          onSelected: (id) => Navigator.of(bottomSheetContext).pop(id),
          onCancel: () => Navigator.of(bottomSheetContext).pop(),
        );
      },
    );
  }

  String _habitId(Map<String, dynamic> habit) {
    final value = (habit['id'] ?? habit['habitId'] ?? '').toString().trim();
    return value;
  }

  String _habitTitle(Map<String, dynamic> habit) {
    final title = (habit['title'] ??
            habit['name'] ??
            habit['habitTitle'] ??
            habit['label'] ??
            habit['id'] ??
            '')
        .toString()
        .trim();
    return title.isEmpty ? 'Hábito' : title;
  }

  String _habitSubtitle(Map<String, dynamic> habit) {
    final value = (habit['familyName'] ??
            habit['family'] ??
            habit['routine'] ??
            habit['frequency'] ??
            '')
        .toString()
        .trim();
    return value.isEmpty ? 'Hábito activo' : value;
  }

  bool _isArchivedHabit(Map<String, dynamic> habit) {
    return habit['archived'] == true || habit['isArchived'] == true;
  }

  String _habitTitleFromHabitId(
    List<Map<String, dynamic>> habits,
    String habitId,
  ) {
    for (final habit in habits) {
      if (_habitId(habit) == habitId) {
        return _habitTitle(habit);
      }
    }
    return habitId;
  }

  String _streakOperationId(String prefix, String subjectId) {
    return '${prefix}_${subjectId.trim()}_${DateTime.now().microsecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _snapshot == null) {
      if (!_loading &&
          widget.controller.isCloudEconomyEnabled &&
          _economyStatus != null &&
          !_isRenderableEconomyStatus(_economyStatus!)) {
        return _buildEconomyUnavailableState(_economyStatus!);
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final snapshot = _snapshot!;

    return PopScope(
      canPop: _stack.length <= 1,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && _stack.length > 1) {
          _popPage();
        }
      },
      child: _buildCurrentPage(snapshot),
    );
  }

  Widget _buildEconomyUnavailableState(ShopCloudEconomyStatus status) {
    final message = switch (status) {
      ShopCloudEconomyStatus.walletMissing =>
        'No encontramos la wallet cloud de este usuario.',
      ShopCloudEconomyStatus.unauthenticated =>
        'Inicia sesión para ver la tienda cloud.',
      ShopCloudEconomyStatus.failed => 'No pudimos cargar la wallet cloud.',
      ShopCloudEconomyStatus.loading =>
        'La wallet cloud todavía se está cargando.',
      ShopCloudEconomyStatus.disabled => 'La tienda cloud está desactivada.',
      ShopCloudEconomyStatus.ready => 'La tienda cloud está lista.',
      ShopCloudEconomyStatus.stale =>
        'La wallet cloud está temporalmente desactualizada.',
    };

    return Scaffold(
      body: Center(
        child: ShopEmptyState(
          title: 'Tienda no disponible',
          message: message,
        ),
      ),
    );
  }

  Widget _buildCurrentPage(ShopFlowSnapshot snapshot) {
    final _ShopFlowPage page = _stack.last;

    switch (page) {
      case _ShopFlowPage.home:
        return ShopHomeScreen(
          walletCoins: snapshot.walletCoins,
          onOpenCosmetics: _openCosmetics,
          onOpenUtilities: _openUtilities,
          onOpenBackpack: _openBackpack,
          onOpenCustomization: _openCustomization,
          drawer: AppViewDrawer(
            selected: 'shop',
            onGoDaily: () => _navReplace(context, const HomeScreen()),
            onGoWeekly: () => _navReplace(context, const HabitWeeklyScreen()),
            onGoMonthly: () => _navReplace(context, const HabitMonthlyScreen()),
            onGoTodo: () => Navigator.pushNamed(context, '/todo'),
            onGoDiary: () => _navReplace(context, const DiaryV2Screen()),
            onGoDiaryV2: () =>
                Navigator.of(context).pushReplacementNamed('/diary'),
            onGoArchived: () =>
                _navReplace(context, const ArchivedHabitsScreen()),
            onGoStats: () => _navReplace(context, const StatisticsV3Screen()),
            onGoShop: () {},
            onGoProfile: () => _navReplace(context, const ProfileScreen()),
          ),
        );
      case _ShopFlowPage.cosmetics:
        return ShopCosmeticsScreen(
          controller: widget.cosmeticsController,
          onBackPressed: _popPage,
        );
      case _ShopFlowPage.utilities:
        return ShopUtilitiesScreen(
          walletCoins: snapshot.walletCoins,
          items: snapshot.utilityCatalogItems,
          onBackPressed: _popPage,
          onItemPressed: _openDetail,
        );
      case _ShopFlowPage.collections:
        return ShopCollectionsScreen(
          walletCoins: snapshot.walletCoins,
          collections: snapshot.collections,
          ownedItemIds: snapshot.ownedItemIds,
          onBackPressed: _popPage,
          onCollectionPressed: _openCollection,
        );
      case _ShopFlowPage.backpack:
        return ShopBackpackScreen(
          walletCoins: snapshot.walletCoins,
          items: snapshot.backpackViewModels,
          activeEffects: snapshot.activeUtilityEffects,
          pendingMysteryBoxOpenings: snapshot.pendingMysteryBoxOpenings,
          onBackPressed: _popPage,
          onItemPressed: _openDetail,
          onUsePressed: _handleUsePressed,
          onOpenUtilities: _openUtilities,
          onContinueMysteryBoxOpening: _showMysteryBoxOpening,
        );
      case _ShopFlowPage.customization:
        return ShopCustomizationScreen(
          walletCoins: snapshot.walletCoins,
          equippedCosmetics: snapshot.equippedCosmetics,
          ownedCosmeticItems: snapshot.ownedCosmeticItems,
          cosmeticsController: widget.cosmeticsController,
          onBackPressed: _popPage,
          onEquipPressed: _handleCosmeticsEquipPressed,
          onItemPressed: _openDetail,
          onOpenCosmetics: _openCosmetics,
        );
      case _ShopFlowPage.detail:
        final String? itemId = _selectedItemId;
        if (itemId == null) {
          return const Scaffold(
            body: Center(
              child: ShopEmptyState(
                title: 'Detalle no disponible',
                message: 'No pudimos abrir este item.',
              ),
            ),
          );
        }

        final ShopItem? item = ShopCatalog.getItemById(itemId);
        if (item == null) {
          return const Scaffold(
            body: Center(
              child: ShopEmptyState(
                title: 'Detalle no disponible',
                message: 'No pudimos abrir este item.',
              ),
            ),
          );
        }

        final String? collectionName = item.collectionId == null
            ? null
            : snapshot.collectionById(item.collectionId!)?.title;

        if (item.cosmeticSlot != null) {
          return ShopCosmeticDetailContainer(
            itemId: itemId,
            controller: widget.cosmeticsController,
            onBackPressed: _popPage,
            collectionName: collectionName,
            onEquipCompleted: (_) => _reloadSnapshot(),
          );
        }

        return ShopItemDetailContainer.withController(
          itemId: itemId,
          onBackPressed: _popPage,
          controller: widget.controller,
          collectionName: collectionName,
          onPurchaseCompleted: _handlePurchaseCompleted,
          onEquipCompleted: _handleEquipCompleted,
        );
    }
  }
}

class _SelectableSheetItem {
  const _SelectableSheetItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String id;
  final String title;
  final String subtitle;
  final String trailing;
}

class _StreakSelectionSheet extends StatelessWidget {
  const _StreakSelectionSheet({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.onSelected,
    required this.onCancel,
  });

  final String title;
  final String subtitle;
  final List<_SelectableSheetItem> items;
  final ValueChanged<String> onSelected;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.68,
          minChildSize: 0.42,
          maxChildSize: 0.88,
          builder: (
            BuildContext context,
            ScrollController scrollController,
          ) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: ShopUiTextStyles.pageTitle.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: ShopUiTextStyles.subtitle,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (BuildContext context, int index) {
                        final item = items[index];
                        return _StreakSelectionTile(
                          item: item,
                          onTap: () => onSelected(item.id),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StreakSelectionTile extends StatelessWidget {
  const _StreakSelectionTile({
    required this.item,
    required this.onTap,
  });

  final _SelectableSheetItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ShopUiTokens.surfaceRaised,
      borderRadius: ShopUiTokens.radiusLgShape,
      child: InkWell(
        onTap: onTap,
        borderRadius: ShopUiTokens.radiusLgShape,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ShopUiTextStyles.cardTitle.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ShopUiTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                item.trailing,
                style: ShopUiTextStyles.labelSmall.copyWith(
                  color: ShopUiTokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
