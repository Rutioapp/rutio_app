import 'package:flutter/material.dart';
import 'package:rutio/features/shop/application/shop_controller.dart';
import 'package:rutio/features/shop/presentation/screens/shop_item_detail_screen.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_empty_state.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_header.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_page_shell.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_purchase_confirmation_sheet.dart';

typedef ShopItemStateLoader = Future<ShopItemState?> Function(String itemId);
typedef ShopItemPurchaseHandler = Future<ShopControllerResult> Function(
  String itemId,
);
typedef ShopItemEquipHandler = Future<ShopControllerResult> Function(
  String itemId,
);

class ShopItemDetailContainer extends StatefulWidget {
  const ShopItemDetailContainer({
    super.key,
    required this.itemId,
    required this.onBackPressed,
    required this.loadItemState,
    required this.purchaseItem,
    required this.equipItem,
    this.collectionName,
    this.onPurchaseCompleted,
    this.onEquipCompleted,
  });

  factory ShopItemDetailContainer.withController({
    Key? key,
    required String itemId,
    required VoidCallback onBackPressed,
    required ShopController controller,
    String? collectionName,
    ValueChanged<ShopControllerResult>? onPurchaseCompleted,
    ValueChanged<ShopControllerResult>? onEquipCompleted,
  }) {
    return ShopItemDetailContainer(
      key: key,
      itemId: itemId,
      onBackPressed: onBackPressed,
      loadItemState: controller.getItemState,
      purchaseItem: controller.purchaseItem,
      equipItem: controller.equipItem,
      collectionName: collectionName,
      onPurchaseCompleted: onPurchaseCompleted,
      onEquipCompleted: onEquipCompleted,
    );
  }

  final String itemId;
  final VoidCallback onBackPressed;
  final ShopItemStateLoader loadItemState;
  final ShopItemPurchaseHandler purchaseItem;
  final ShopItemEquipHandler equipItem;
  final String? collectionName;
  final ValueChanged<ShopControllerResult>? onPurchaseCompleted;
  final ValueChanged<ShopControllerResult>? onEquipCompleted;

  @override
  State<ShopItemDetailContainer> createState() => _ShopItemDetailContainerState();
}

class _ShopItemDetailContainerState extends State<ShopItemDetailContainer> {
  ShopItemState? _itemState;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refreshItemState();
  }

  Future<void> _refreshItemState() async {
    setState(() {
      _loading = true;
    });

    final ShopItemState? state = await widget.loadItemState(widget.itemId);
    if (!mounted) return;

    setState(() {
      _itemState = state;
      _loading = false;
    });
  }

  Future<void> _handlePurchaseRequested(String itemId) async {
    final ShopItemState? state = _itemState;
    if (state == null || _busy) return;

    final bool? shouldConfirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      ),
      builder: (BuildContext context) {
        return ShopPurchaseConfirmationSheet(
          item: state.item,
          walletCoins: state.walletCoins,
          onCancel: () => Navigator.of(context).pop(false),
          onConfirm: (_) => Navigator.of(context).pop(true),
        );
      },
    );

    if (shouldConfirm != true || !mounted) return;

    setState(() {
      _busy = true;
    });

    final ShopControllerResult result = await widget.purchaseItem(itemId);
    if (!mounted) return;

    widget.onPurchaseCompleted?.call(result);
    await _refreshItemState();

    setState(() {
      _busy = false;
    });

    _showFeedback(_purchaseFeedbackMessage(result));
  }

  Future<void> _handleEquipRequested(String itemId) async {
    if (_busy) return;

    setState(() {
      _busy = true;
    });

    final ShopControllerResult result = await widget.equipItem(itemId);
    if (!mounted) return;

    widget.onEquipCompleted?.call(result);
    await _refreshItemState();

    setState(() {
      _busy = false;
    });

    _showFeedback(_equipFeedbackMessage(result));
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.fixed,
        backgroundColor: ShopUiTokens.textPrimary,
      ),
    );
  }

  String _purchaseFeedbackMessage(ShopControllerResult result) {
    if (result.status == ShopControllerStatus.success) {
      final bool isCosmetic = result.item?.cosmeticSlot != null;
      return isCosmetic
          ? 'Añadido a tu colección'
          : 'Añadido a la mochila';
    }
    return 'No se ha podido completar la compra';
  }

  String _equipFeedbackMessage(ShopControllerResult result) {
    if (result.status == ShopControllerStatus.success) {
      return 'Cosmético equipado';
    }
    return 'No se ha podido equipar el item';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final ShopItemState? state = _itemState;
    if (state == null) {
      return ShopPageShell(
        header: ShopHeader(
          title: 'Detalle',
          leadingIcon: Icons.arrow_back_ios_new_rounded,
          onLeadingPressed: widget.onBackPressed,
        ),
        child: const ShopEmptyState(
          title: 'Item no disponible',
          message: 'No hemos podido cargar este item de la tienda.',
        ),
      );
    }

    return Stack(
      children: <Widget>[
        ShopItemDetailScreen(
          item: state.item,
          walletCoins: state.walletCoins,
          isOwned: state.isOwned,
          isEquipped: state.isEquipped,
          backpackQuantity:
              state.backpackQuantity > 0 ? state.backpackQuantity : null,
          collectionName: widget.collectionName,
          onBackPressed: widget.onBackPressed,
          onPurchasePressed: _handlePurchaseRequested,
          onEquipPressed: _handleEquipRequested,
        ),
        if (_busy)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.04),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }
}
