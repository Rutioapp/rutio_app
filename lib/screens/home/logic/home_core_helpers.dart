part of 'package:rutio/screens/home/home_screen.dart';

/// Core helpers tied to Home screen state/UI orchestration.
///
/// Keeps lightweight methods that still need direct access to `_HomeScreenState`,
/// but do not belong to dialogs, actions, selectors or widgets.
extension _HomeScreenCoreHelpers on _HomeScreenState {}
