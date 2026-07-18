import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rutio/features/shop/application/shop_cosmetics_controller.dart';
import 'package:rutio/features/shop/application/shop_controller.dart';
import 'package:rutio/features/shop/data/shop_local_repository.dart';
import 'package:rutio/features/shop/presentation/screens/shop_flow_screen.dart';
import 'package:rutio/stores/user_state_store.dart';

class ShopScreen extends StatefulWidget {
  // Legacy wrapper. The final shop experience lives in ShopFlowScreen.
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late final ShopLocalRepository _shopRepository;
  late final ShopController _shopController;

  @override
  void initState() {
    super.initState();
    final userStateStore = context.read<UserStateStore>();
    _shopRepository = ShopLocalRepository(
      scopeResolver: () =>
          userStateStore.activeLocalScopeUserId ?? userStateStore.userId,
    );
    _shopController = ShopController(
      userStateStore: userStateStore,
      shopRepository: _shopRepository,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cosmeticsController = context.read<ShopCosmeticsController>();

    return ShopFlowScreen(
      controller: _shopController,
      cosmeticsController: cosmeticsController,
      shopRepository: _shopRepository,
    );
  }
}
