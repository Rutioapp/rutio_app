import 'dart:async';
import 'dart:convert';

import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rutio/core/assets/app_assets.dart';

import 'package:rutio/constants/color_palette.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/screens/diary/diary_screen.dart';
import 'package:rutio/screens/habit_archived_screen.dart';
import 'package:rutio/screens/habit_detail/habit_detail_screen.dart';
import 'package:rutio/screens/habit_detail/widgets/editor/habit_editor_utils.dart';
import 'package:rutio/screens/habit_monthly_overview_screen.dart';
import 'package:rutio/screens/habit_stats_overview_screen.dart';
import 'package:rutio/screens/habit_weekly_screen.dart';
import 'package:rutio/screens/profile/profile_screen.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:rutio/ui/behaviours/ios_feedback.dart';
import 'package:rutio/ui/foundations/ios_foundations.dart';
import 'package:rutio/utils/family_theme.dart';
import 'package:rutio/widgets/app_header/app_header.dart';
import 'package:rutio/widgets/app_view_drawer.dart';
import 'package:rutio/widgets/backgrounds/home_landscape_background.dart';
import 'package:rutio/widgets/emoji_picker_bottom_sheet.dart';
import 'package:rutio/widgets/home/add_habit/home_add_habit_sheet.dart';
import 'package:rutio/widgets/home/home_add_fab.dart';
import 'package:rutio/widgets/home/user_identity_row.dart';

import 'package:rutio/screens/home/widgets/chips/home_day_chip.dart';
import 'package:rutio/screens/home/widgets/habit/habit_card_widget.dart';

part 'state/home_state.dart';

part 'build/home_build.dart';
part 'build/sections/home_pinned_header_sliver.dart';
part 'build/sections/home_habits_sliver.dart';
part 'build/sections/home_empty_state_card.dart';
part 'build/sections/home_scrollable_content_sliver.dart';

part 'logic/home_helpers.dart';
part 'logic/home_selectors.dart';
part 'logic/home_core_helpers.dart';
part 'logic/home_formatters.dart';
part 'logic/home_catalog_helpers.dart';
part 'logic/home_view_data.dart';
part 'logic/home_navigation.dart';
part 'logic/home_habit_actions.dart';
part 'logic/home_dialogs.dart';
part 'ui/home_header_builders.dart';
part 'ui/home_card_builders.dart';

part 'nav/home_profile_nav.dart';

/// Opens the "Add habit" bottom sheet from Home FAB.
///
/// Defined here (home_screen library) so `home_build.dart` (a `part`) can call it
/// without needing additional imports inside parts.
Future<void> showHomeAddHabitSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.22),
    builder: (_) => HomeAddHabitSheet(rootContext: context),
  );
}

/// ✅ ALIAS (compatibilidad)
/// Tu Home antigua usa `bg`, `primaryDark`, etc. sin prefijo.
/// Estos alias conectan esos nombres con ColorPalette.
const Color bg = ColorPalette.bg;
const Color surface = ColorPalette.surface;
const Color cardBg = ColorPalette.cardBg;

const Color primary = ColorPalette.primary;
const Color primaryDark = ColorPalette.primaryDark;
const Color accent = ColorPalette.accent;

const Color textPrimary = ColorPalette.textPrimary;
const Color textSecondary = ColorPalette.textSecondary;
const Color divider = ColorPalette.divider;

const Color bgDark = ColorPalette.bgDark;
const Color surfaceDark = ColorPalette.surfaceDark;
const Color cardBgDark = ColorPalette.cardBgDark;

const Color textPrimaryDark = ColorPalette.textPrimaryDark;
const Color textSecondaryDark = ColorPalette.textSecondaryDark;
const Color dividerDark = ColorPalette.dividerDark;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

final ConfettiController _confettiController =
    ConfettiController(duration: const Duration(seconds: 1));
