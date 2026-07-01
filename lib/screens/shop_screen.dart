import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    _shopRepository = ShopLocalRepository();
  }

  @override
  Widget build(BuildContext context) {
    final userStateStore = context.read<UserStateStore>();

    return ShopFlowScreen(
      controller: ShopController(
        userStateStore: userStateStore,
        shopRepository: _shopRepository,
      ),
      shopRepository: _shopRepository,
    );
  }
}
