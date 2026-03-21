import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../stores/user_state_store.dart';
import 'home/home_screen.dart';
import 'welcome_screen.dart';

class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserStateStore>(
      builder: (_, store, __) {
        // ✅ Loading: no mostramos Splash aquí para evitar loops.
        if (store.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (store.error != null) {
          return Scaffold(
            body: Center(
              child: Text(
                context.l10n.homeErrorMessage(store.error.toString()),
              ),
            ),
          );
        }

        if (store.hasSession) {
          return const HomeScreen();
        }

        return const WelcomeScreen();
      },
    );
  }
}
