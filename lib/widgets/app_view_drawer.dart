import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/feedback_form_service.dart';
import '../l10n/l10n.dart';
import '../stores/user_state_store.dart';
import '../utils/app_theme.dart';

/// Drawer unificado con look iOS-first inspirado en la referencia visual.
///
/// Ajustes:
/// - Se elimina la fila visual de "Rutio" dentro de VISTAS.
/// - El drawer ocupa toda la altura de la pantalla, de arriba a abajo.
/// - Usa AppTextStyles para mantener coherencia tipográfica con el resto.
class AppViewDrawer extends StatelessWidget {
  const AppViewDrawer({
    super.key,
    required this.onGoDaily,
    required this.onGoWeekly,
    required this.onGoMonthly,
    required this.onGoTodo,
    required this.onGoDiary,
    required this.onGoArchived,
    required this.onGoStats,
    required this.onGoShop,
    required this.onGoProfile,
    this.selected,
  });

  final VoidCallback onGoDaily;
  final VoidCallback onGoWeekly;
  final VoidCallback onGoMonthly;
  final VoidCallback onGoTodo;
  final VoidCallback onGoDiary;
  final VoidCallback onGoArchived;
  final VoidCallback onGoStats;
  final VoidCallback onGoShop;
  final VoidCallback onGoProfile;

  /// Valores sugeridos:
  /// 'daily'|'weekly'|'monthly'|'todo'|'diary'|'archived'|'stats'|'shop'|'profile'
  final String? selected;

  static const Color _skyTop = Color(0xFFEAF3FB);
  static const Color _skyMid = Color(0xFFD6EAF6);
  static const Color _skySoft = Color(0xFFC8DDED);
  static const Color _earthLight = Color(0xFFD8CEA8);
  static const Color _earthSoft = Color(0xFFE6DCC0);

  static const Color _textPrimary = Color(0xFF151515);
  static const Color _textSecondary = Color(0xFF7E735D);
  static const Color _divider = Color(0x1F6A5E4A);
  static const Color _activeTile = Color(0xFFF2F4F5);
  static const Color _icon = Color(0xFF7B6447);
  static const Color _supportTileBg = Color(0x1AF05A5A);
  static const Color _supportIconBg = Color(0x26F05A5A);
  static const Color _supportIcon = Color(0xFFC44747);
  static const Color _proBg = Color(0xFFF0DEC1);
  static const Color _proText = Color(0xFF9E7A3D);
  static final FeedbackFormService _feedbackFormService = FeedbackFormService();

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = (media.size.width * 0.86).clamp(300.0, 360.0);
    final topInset = media.padding.top;
    final bottomInset = media.padding.bottom;

    return Drawer(
      width: width,
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          height: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_skyTop, _skyMid, _skySoft, _earthLight, _earthSoft],
              stops: [0.0, 0.28, 0.52, 0.78, 1.0],
            ),
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(34),
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(18, topInset + 18, 14, 0),
                  children: [
                    const _DrawerBrandHeader(),
                    const SizedBox(height: 28),
                    _DrawerSectionLabel(context.l10n.drawerSectionViews),
                    const SizedBox(height: 8),
                    _DrawerTile(
                      icon: Icons.calendar_today_outlined,
                      label: context.l10n.drawerDaily,
                      isSelected: selected == 'daily',
                      onTap: () => _go(context, onGoDaily),
                    ),
                    const _DrawerDivider(),
                    _DrawerTile(
                      icon: Icons.view_week_outlined,
                      label: context.l10n.drawerWeekly,
                      isSelected: selected == 'weekly',
                      onTap: () => _go(context, onGoWeekly),
                    ),
                    const _DrawerDivider(),
                    _DrawerTile(
                      icon: Icons.calendar_month_outlined,
                      label: context.l10n.drawerMonthly,
                      isSelected: selected == 'monthly',
                      onTap: () => _go(context, onGoMonthly),
                    ),
                    const SizedBox(height: 18),
                    _DrawerSectionLabel(context.l10n.drawerSectionTracking),
                    const SizedBox(height: 8),
                    _DrawerTile(
                      icon: Icons.checklist_rounded,
                      label: context.l10n.drawerTodo,
                      isSelected: selected == 'todo',
                      onTap: () => _go(context, onGoTodo),
                    ),
                    const _DrawerDivider(),
                    _DrawerTile(
                      icon: Icons.show_chart_rounded,
                      label: context.l10n.drawerStatistics,
                      isSelected: selected == 'stats',
                      onTap: () => _go(context, onGoStats),
                    ),
                    const _DrawerDivider(),
                    _DrawerTile(
                      icon: Icons.menu_book_outlined,
                      label: context.l10n.drawerDiary,
                      isSelected: selected == 'diary',
                      onTap: () => _go(context, onGoDiary),
                    ),
                    const SizedBox(height: 18),
                    _DrawerSectionLabel(context.l10n.drawerSectionArchive),
                    const SizedBox(height: 8),
                    _DrawerTile(
                      icon: Icons.inventory_2_outlined,
                      label: context.l10n.drawerArchived,
                      isSelected: selected == 'archived',
                      onTap: () => _go(context, onGoArchived),
                    ),
                    const SizedBox(height: 18),
                    _DrawerSectionLabel(context.l10n.drawerSectionAccount),
                    const SizedBox(height: 8),
                    _DrawerTile(
                      icon: Icons.storefront_outlined,
                      label: context.l10n.drawerShop,
                      isSelected: selected == 'shop',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: _proBg,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0x33A17E42)),
                        ),
                        child: Text(
                          context.l10n.drawerProBadge,
                          style: AppTextStyles.drawerSection.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: _proText,
                          ),
                        ),
                      ),
                      onTap: () => _go(context, onGoShop),
                    ),
                    const SizedBox(height: 18),
                    _DrawerSectionLabel(context.l10n.drawerSectionSupport),
                    const SizedBox(height: 8),
                    _DrawerTile(
                      icon: CupertinoIcons.exclamationmark_bubble,
                      label: context.l10n.drawerReportIssue,
                      backgroundColor: _supportTileBg,
                      iconBackgroundColor: _supportIconBg,
                      iconColor: _supportIcon,
                      onTap: () => _handleReportIssueTap(context),
                    ),
                    SizedBox(height: 18 + bottomInset),
                  ],
                ),
              ),
              const Divider(height: 1, color: _divider),
              Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: _DrawerProfileFooter(
                  isSelected: selected == 'profile',
                  onTap: () => _go(context, onGoProfile),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, VoidCallback onTap) {
    Navigator.of(context).pop();
    onTap();
  }

  Future<void> _handleReportIssueTap(BuildContext context) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final store = context.read<UserStateStore>();
    final reporterName = (store.displayName ?? '').trim();
    final userId = (store.userId ?? '').trim();
    final email = store.authEmail ?? '';
    final reportIdentity = reporterName.isNotEmpty ? reporterName : userId;

    Navigator.of(context).pop();

    bool didLaunch = false;
    try {
      didLaunch = await _feedbackFormService.launchReportIssueForm(
        userId: reportIdentity,
        email: email,
      );
    } catch (_) {
      didLaunch = false;
    }
    if (!didLaunch && messenger != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.drawerReportIssueLaunchError)),
        );
    }
  }
}

class _DrawerBrandHeader extends StatelessWidget {
  const _DrawerBrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.drawerBrandName,
          style: AppTextStyles.brandName.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.7,
            color: AppViewDrawer._textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          context.l10n.drawerBrandTagline,
          style: AppTextStyles.brandSub.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 3.2,
            color: AppViewDrawer._textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        const SizedBox(
          width: 28,
          child: Divider(
            height: 1,
            thickness: 1.4,
            color: Color(0xFFB2A58B),
          ),
        ),
      ],
    );
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  const _DrawerSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.drawerSection);
  }
}

class _DrawerDivider extends StatelessWidget {
  const _DrawerDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 6),
      child: Divider(height: 1, color: AppViewDrawer._divider),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
    this.trailing,
    this.backgroundColor,
    this.iconColor,
    this.iconBackgroundColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;
  final Widget? trailing;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final resolvedBackgroundColor = isSelected
        ? AppViewDrawer._activeTile
        : backgroundColor ?? Colors.transparent;

    return Material(
      color: resolvedBackgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: iconColor ?? AppViewDrawer._icon,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: isSelected
                        ? AppTextStyles.drawerItemActive
                        : AppTextStyles.drawerItem,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerProfileFooter extends StatelessWidget {
  const _DrawerProfileFooter({
    required this.onTap,
    required this.isSelected,
  });

  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x26A68B62),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  size: 18,
                  color: AppViewDrawer._icon,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.drawerProfile,
                      style: isSelected
                          ? AppTextStyles.drawerItemActive
                          : AppTextStyles.drawerItem,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.drawerProfileVersion,
                      style: AppTextStyles.drawerFooter.copyWith(
                        color: AppViewDrawer._textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_upward_rounded,
                size: 18,
                color: Color(0xFFB2A58B),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
