import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/application/sync/pending_sync_status.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/widgets/home/sync_status_indicator.dart';

Widget buildApp({required Widget child, Locale locale = const Locale('es')}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('synchronized status is hidden', (tester) async {
    await tester.pumpWidget(
      buildApp(
        child: const HomeSyncStatusIndicator(
          status: SyncStatusSnapshot.signedOut(),
        ),
      ),
    );
    expect(find.byType(HomeSyncStatusIndicator), findsOneWidget);
    expect(find.byIcon(Icons.cloud_queue), findsNothing);
    expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
  });

  testWidgets('pending and attention states expose localized semantics',
      (tester) async {
    await tester.pumpWidget(
      buildApp(
        child: const HomeSyncStatusIndicator(
          status: SyncStatusSnapshot(
            userId: 'user-a',
            kind: SyncStatusKind.pending,
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.cloud_queue), findsOneWidget);
    expect(find.bySemanticsLabel('Pendiente de sincronizar'), findsOneWidget);

    await tester.pumpWidget(
      buildApp(
        child: const HomeSyncStatusIndicator(
          status: SyncStatusSnapshot(
            userId: 'user-a',
            kind: SyncStatusKind.attention,
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    expect(
      find.bySemanticsLabel('Sincronización pendiente de revisión'),
      findsOneWidget,
    );
  });

  testWidgets('english label and large text fit without overflow',
      (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(3)),
        child: buildApp(
          locale: const Locale('en'),
          child: const HomeSyncStatusIndicator(
            status: SyncStatusSnapshot(
              userId: 'user-a',
              kind: SyncStatusKind.pending,
            ),
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Pending sync'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
