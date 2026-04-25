import 'package:flutter/widgets.dart';
import '../features/achievements/domain/models/achievement.dart';
import '../core/notifications/notification_permission_service.dart';
import '../core/permissions/app_permission.dart';
import 'gen/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension AppLocalizationsUserSharedX on AppLocalizations {
  bool get _isSpanishUserShared => localeName.toLowerCase().startsWith('es');

  String get userLevelLabel => _isSpanishUserShared ? 'Nivel' : 'Level';

  String userLevelShort(int level) =>
      _isSpanishUserShared ? 'NV. $level' : 'LVL. $level';
}

extension AppLocalizationsProfileX on AppLocalizations {
  bool get _isSpanish => localeName.toLowerCase().startsWith('es');

  String get profileTitle => _isSpanish ? 'Perfil' : 'Profile';

  String get profileDefaultName => _isSpanish ? 'Tu perfil' : 'Your profile';

  String get profileDefaultSubtitle => _isSpanish
      ? 'Tu progreso, ajustes y cuenta'
      : 'Your progress, settings and account';

  String get profileNotificationsTitle =>
      _isSpanish ? 'Notificaciones' : 'Notifications';

  String get profileEnableNotificationsTitle =>
      _isSpanish ? 'Activar notificaciones' : 'Enable notifications';

  String get profileEnableNotificationsSubtitle => _isSpanish
      ? 'Recordatorios, cierre del d\u00eda y rachas'
      : 'Reminders, end-of-day prompts and streaks';

  String get profileNotificationSettingsTitle =>
      _isSpanish ? 'Ajustes de notificaciones' : 'Notification settings';

  String profileNotificationCategoriesActive(int count, int total) {
    return _isSpanish
        ? '$count de $total categor\u00edas activas'
        : '$count of $total active categories';
  }

  String get profileAccountSectionTitle =>
      _isSpanish ? 'Cuenta y ajustes' : 'Account and settings';

  String get profileThemeTitle => _isSpanish ? 'Tema' : 'Theme';

  String get profileThemeSubtitle => _isSpanish
      ? 'Claro / Oscuro / Autom\u00e1tico'
      : 'Light / Dark / Automatic';

  String get profileThemeTodo => _isSpanish ? 'Tema (TODO)' : 'Theme (TODO)';

  String get profileHelpTitle => _isSpanish ? 'Ayuda' : 'Help';

  String get profileHelpSubtitle =>
      _isSpanish ? 'FAQ y soporte' : 'FAQ and support';

  String get profileHelpTodo => _isSpanish ? 'Ayuda (TODO)' : 'Help (TODO)';

  String get profileAboutTitle => _isSpanish ? 'Acerca de' : 'About';

  String get profileAboutSubtitle =>
      _isSpanish ? 'Versi\u00f3n y legal' : 'Version and legal';

  String get profileAboutTodo =>
      _isSpanish ? 'Acerca de (TODO)' : 'About (TODO)';

  String get profileDangerSectionTitle =>
      _isSpanish ? 'Zona peligrosa' : 'Danger zone';

  String get profileManageDataTitle =>
      _isSpanish ? 'Gestionar datos' : 'Manage data';

  String get profileManageDataSubtitle => _isSpanish
      ? 'Exportar o borrar tu informaci\u00f3n'
      : 'Export or delete your information';

  String get profileManageDataTodo =>
      _isSpanish ? 'Gestionar datos (TODO)' : 'Manage data (TODO)';

  String get profileLogoutTodo =>
      _isSpanish ? 'Cerrar sesi\u00f3n (TODO)' : 'Log out (TODO)';

  String get profileNotificationPermissionDenied => _isSpanish
      ? 'Permiso de notificaciones no concedido.'
      : 'Notification permission was not granted.';

  String get profileNotificationPermissionSettings => _isSpanish
      ? 'Activa las notificaciones en Ajustes para recibir recordatorios de Rutio.'
      : 'Enable notifications in Settings to receive Rutio reminders.';

  String get commonOpenSettings =>
      _isSpanish ? 'Abrir ajustes' : 'Open settings';

  String notificationPermissionMessage(
    NotificationPermissionStatus status,
  ) {
    switch (status) {
      case NotificationPermissionStatus.notDetermined:
      case NotificationPermissionStatus.denied:
        return profileNotificationPermissionDenied;
      case NotificationPermissionStatus.restricted:
      case NotificationPermissionStatus.permanentlyDenied:
        return profileNotificationPermissionSettings;
      case NotificationPermissionStatus.provisional:
        return _isSpanish
            ? 'Las notificaciones están permitidas de forma provisional.'
            : 'Notifications are currently allowed provisionally.';
      case NotificationPermissionStatus.authorized:
        return _isSpanish
            ? 'Las notificaciones están activadas.'
            : 'Notifications are enabled.';
      case NotificationPermissionStatus.unknown:
        return profileNotificationPermissionDenied;
    }
  }

  String get profileEditButton => _isSpanish ? 'Editar' : 'Edit';

  String get profileDangerZoneTitle =>
      _isSpanish ? 'Zona de peligro' : 'Danger zone';

  String get profileLogoutTitle =>
      _isSpanish ? 'Cerrar sesi\u00f3n' : 'Log out';

  String get profileLogoutSubtitle => _isSpanish
      ? 'Se cerrar\u00e1 tu sesi\u00f3n en este dispositivo'
      : 'Your session will be closed on this device';

  String get profileDeleteDataTitle =>
      _isSpanish ? 'Borrar datos' : 'Delete data';

  String get profileDeleteDataSubtitle => _isSpanish
      ? 'Elimina todos tus datos y progreso (irreversible)'
      : 'Delete all your data and progress (irreversible)';

  String get profileFamiliesProgressTitle =>
      _isSpanish ? 'Progreso por familias' : 'Progress by family';

  String profileFamilyLevelShort(int level) => 'Lvl $level';

  String profileFamilyLevelLabel(int level) =>
      _isSpanish ? 'Nivel $level' : 'Level $level';

  String get profileNotificationsPhaseOneTitle =>
      _isSpanish ? 'Fase 1' : 'Phase 1';

  String get profileNotificationHabitRemindersTitle =>
      _isSpanish ? 'Recordatorios de h\u00e1bitos' : 'Habit reminders';

  String get profileNotificationHabitRemindersSubtitle => _isSpanish
      ? 'Respeta la hora configurada en cada h\u00e1bito'
      : 'Respect the time configured for each habit';

  String get profileNotificationDayClosureTitle =>
      _isSpanish ? 'Cierre del d\u00eda' : 'End of day';

  String get profileNotificationDayClosureSubtitle => _isSpanish
      ? 'Solo si a\u00fan quedan h\u00e1bitos pendientes hoy'
      : 'Only if there are still pending habits today';

  String get profileNotificationDayClosureTimeTitle =>
      _isSpanish ? 'Hora de cierre del d\u00eda' : 'End-of-day time';

  String get profileNotificationDayClosureTimeSubtitle => _isSpanish
      ? 'Momento para recordar lo que a\u00fan queda pendiente'
      : 'A moment to remember what is still pending';

  String get profileNotificationStreakRiskTitle =>
      _isSpanish ? 'Racha en riesgo' : 'Streak at risk';

  String get profileNotificationStreakRiskSubtitle => _isSpanish
      ? 'Avisa cuando a\u00fan puedes salvar una racha relevante'
      : 'Alert when you can still save an important streak';

  String get profileNotificationStreakCelebrationTitle =>
      _isSpanish ? 'Celebraciones de racha' : 'Streak celebrations';

  String get profileNotificationStreakCelebrationSubtitle => _isSpanish
      ? 'Celebra hitos b\u00e1sicos como 1, 3, 7, 14 y 30 d\u00edas'
      : 'Celebrate basic milestones like 1, 3, 7, 14 and 30 days';

  String get profileNotificationInactivityTitle => _isSpanish
      ? 'Reactivaci\u00f3n por inactividad'
      : 'Reactivation after inactivity';

  String get profileNotificationInactivitySubtitle => _isSpanish
      ? 'Un recordatorio amable tras 3 d\u00edas sin abrir la app'
      : 'A gentle reminder after 3 days without opening the app';
}

extension AppLocalizationsAchievementsX on AppLocalizations {
  bool get _isSpanishAchievements =>
      localeName.toLowerCase().startsWith('es');

  String get profileFeaturedAchievementsTitle =>
      _isSpanishAchievements ? 'Logros destacados' : 'Featured achievements';

  String get profileFeaturedAchievementsSubtitle => _isSpanishAchievements
      ? 'Tus badges favoritos desbloqueados'
      : 'Your favorite unlocked badges';

  String get profileFeaturedAchievementsHint => _isSpanishAchievements
      ? 'Toca para elegir hasta 3 logros destacados'
      : 'Tap to choose up to 3 featured achievements';

  String get profileFeaturedAchievementsEmptyTitle => _isSpanishAchievements
      ? 'A\u00fan no tienes destacados'
      : 'You have no featured achievements yet';

  String get profileFeaturedAchievementsEmptySubtitle => _isSpanishAchievements
      ? 'Desbloquea badges y elige los que quieras mostrar en tu perfil'
      : 'Unlock badges and choose the ones you want to show on your profile';

  String get profileAchievementsTitle =>
      _isSpanishAchievements ? 'Logros' : 'Achievements';

  String get profileAchievementsSubtitle => _isSpanishAchievements
      ? 'Consulta tu progreso y badges desbloqueados'
      : 'Review your progress and unlocked badges';

  String get achievementsTitle =>
      _isSpanishAchievements ? 'Logros' : 'Achievements';

  String get achievementsSpecialLabel =>
      _isSpanishAchievements ? 'Especial' : 'Special';

  String get achievementsSpecialSectionTitle =>
      _isSpanishAchievements ? 'ESPECIALES' : 'SPECIAL';

  String get achievementsFilterAll => _isSpanishAchievements ? 'Todos' : 'All';

  String get achievementsFilterUnlocked =>
      _isSpanishAchievements ? 'Desbloqueados' : 'Unlocked';

  String get achievementsFilterInProgress =>
      _isSpanishAchievements ? 'En progreso' : 'In progress';

  String get achievementsEmptyAll => _isSpanishAchievements
      ? 'Tus logros aparecer\u00e1n aqu\u00ed a medida que avances con tus h\u00e1bitos.'
      : 'Your achievements will appear here as you progress with your habits.';

  String get achievementsEmptyUnlocked => _isSpanishAchievements
      ? 'Todav\u00eda no has desbloqueado logros.'
      : 'You have not unlocked any achievements yet.';

  String get achievementsEmptyInProgress => _isSpanishAchievements
      ? 'A\u00fan no hay logros con progreso activo.'
      : 'There are no achievements with active progress yet.';

  String achievementsSectionUnlockedCount(int unlockedCount, int totalCount) =>
      _isSpanishAchievements
          ? '$unlockedCount / $totalCount desbloqueados'
          : '$unlockedCount / $totalCount unlocked';

  String achievementsSummaryUnlockedOf(int totalCount) => _isSpanishAchievements
      ? 'desbloqueados\nde $totalCount'
      : 'unlocked\nof $totalCount';

  String get achievementsSummaryProgressTitle =>
      _isSpanishAchievements ? 'Progreso total' : 'Total progress';

  String get achievementsFeaturedPickerTitle =>
      _isSpanishAchievements ? 'Destacar logros' : 'Feature achievements';

  String achievementsFeaturedPickerSubtitle(int selectedCount) =>
      _isSpanishAchievements
          ? '$selectedCount de 3 seleccionados'
          : '$selectedCount of 3 selected';

  String get achievementsFeaturedPickerEmpty => _isSpanishAchievements
      ? 'Necesitas desbloquear al menos un logro para destacarlo.'
      : 'You need to unlock at least one achievement before featuring it.';

  String achievementsFeaturedPickerFamilySubtitle(
    String familyName,
    int targetValue,
  ) =>
      _isSpanishAchievements
          ? '$familyName \u00b7 $targetValue d\u00edas'
          : '$familyName \u00b7 $targetValue days';

  String get achievementsHiddenDescription => _isSpanishAchievements
      ? 'Este logro sigue siendo un misterio.'
      : 'This achievement is still a mystery.';

  String get achievementsMysteryTitle =>
      _isSpanishAchievements ? 'Logro oculto' : 'Hidden achievement';

  String get achievementsMysterySubtitle => _isSpanishAchievements
      ? 'Su m\u00e9todo de desbloqueo se revelar\u00e1 cuando llegue el momento.'
      : 'Its unlock method will be revealed when the time comes.';

  String get achievementsUnlockedCalloutTitle =>
      _isSpanishAchievements ? 'Logro conseguido' : 'Achievement earned';

  String get achievementsUnlockedDateTitle =>
      _isSpanishAchievements ? 'Fecha de desbloqueo' : 'Unlocked on';

  String achievementsUnlockedOnDate(String dateLabel) => _isSpanishAchievements
      ? 'Desbloqueado el $dateLabel.'
      : 'Unlocked on $dateLabel.';

  String get achievementsCurrentStreakTitle =>
      _isSpanishAchievements ? 'Racha actual' : 'Current streak';

  String achievementsCurrentStreakValue(int days) => _isSpanishAchievements
      ? '$days d\u00edas seguidos'
      : '$days days in a row';

  String get achievementsHowToUnlockTitle =>
      _isSpanishAchievements ? 'C\u00f3mo conseguirlo' : 'How to unlock';

  String get achievementsProgressTitle =>
      _isSpanishAchievements ? 'Progreso actual' : 'Current progress';

  String achievementsProgressValue(int current, int target) =>
      '$current / $target';

  String get achievementsOverlayTitle => _isSpanishAchievements
      ? 'Nuevo logro desbloqueado'
      : 'New achievement unlocked';

  String achievementsLatestUnlockedEyebrow(String familyName) =>
      _isSpanishAchievements
          ? '\u00daLTIMO DESBLOQUEADO \u00b7 ${familyName.toUpperCase()}'
          : 'LATEST UNLOCKED \u00b7 ${familyName.toUpperCase()}';

  String achievementsFamilyConsistencySummary(String familyName, int days) =>
      _isSpanishAchievements
          ? '$days d\u00edas de constancia en $familyName.'
          : '$days days of consistency in $familyName.';

  String get achievementsDetailSpecialChipTitle =>
      _isSpanishAchievements ? 'LOGRO ESPECIAL' : 'SPECIAL ACHIEVEMENT';

  String get achievementsCloseButton =>
      _isSpanishAchievements ? 'Cerrar' : 'Close';

  String get achievementsRevealProgressHint => _isSpanishAchievements
      ? 'Desc\u00fabr\u00edalo para revelar su progreso'
      : 'Unlock it to reveal its progress';

  String achievementUnlockedMessage(String habitName, int days) =>
      _isSpanishAchievements
          ? 'Has alcanzado $days d\u00edas seguidos en $habitName'
          : 'You reached $days consecutive days in $habitName';

  String achievementFamilyUnlockedMessage(String familyName, int days) =>
      _isSpanishAchievements
          ? 'Has alcanzado $days d\u00edas de constancia en $familyName'
          : 'You reached $days days of consistency in $familyName';

  String achievementHabitStreakDescription(int days) => _isSpanishAchievements
      ? 'Mant\u00e9n $days d\u00edas seguidos con este h\u00e1bito.'
      : 'Keep this habit going for $days consecutive days.';

  String achievementTierLabel(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.oldWood:
        return _isSpanishAchievements ? 'Madera vieja' : 'Old wood';
      case AchievementTier.wood:
        return _isSpanishAchievements ? 'Madera' : 'Wood';
      case AchievementTier.stone:
        return _isSpanishAchievements ? 'Piedra' : 'Stone';
      case AchievementTier.bronze:
        return _isSpanishAchievements ? 'Bronce' : 'Bronze';
      case AchievementTier.silver:
        return _isSpanishAchievements ? 'Plata' : 'Silver';
      case AchievementTier.gold:
        return _isSpanishAchievements ? 'Oro' : 'Gold';
      case AchievementTier.diamond:
        return _isSpanishAchievements ? 'Diamante' : 'Diamond';
      case AchievementTier.prismaticDiamond:
        return _isSpanishAchievements
            ? 'Diamante prism\u00e1tico'
            : 'Prismatic diamond';
    }
  }
}

extension AppLocalizationsDrawerSupportX on AppLocalizations {
  bool get _isSpanishDrawerSupport => localeName.toLowerCase().startsWith('es');

  String get drawerSectionSupport =>
      _isSpanishDrawerSupport ? 'AYUDA' : 'SUPPORT';

  String get drawerReportIssue =>
      _isSpanishDrawerSupport ? 'Reportar incidencia' : 'Report an issue';

  String get drawerReportIssueLaunchError => _isSpanishDrawerSupport
      ? 'No se pudo abrir el formulario. Inténtalo de nuevo en un momento.'
      : 'Could not open the form. Please try again in a moment.';
}

extension AppLocalizationsEditProfileX on AppLocalizations {
  bool get _isSpanishEditProfile => localeName.toLowerCase().startsWith('es');

  String get editProfileTitle =>
      _isSpanishEditProfile ? 'Editar perfil' : 'Edit profile';

  String get editProfileSave => _isSpanishEditProfile ? 'Guardar' : 'Save';

  String get editProfileSaveChanges =>
      _isSpanishEditProfile ? 'Guardar cambios' : 'Save changes';

  String get editProfileSaving =>
      _isSpanishEditProfile ? 'Guardando...' : 'Saving...';

  String get editProfileTakePhoto =>
      _isSpanishEditProfile ? 'Tomar foto' : 'Take photo';

  String get editProfileGallery =>
      _isSpanishEditProfile ? 'Galer\u00eda' : 'Gallery';

  String get editProfileRemovePhoto =>
      _isSpanishEditProfile ? 'Eliminar foto' : 'Remove photo';

  String get editProfilePersonalInfoTitle => _isSpanishEditProfile
      ? 'Informaci\u00f3n personal'
      : 'Personal information';

  String get editProfileGoalSectionTitle =>
      _isSpanishEditProfile ? 'Tu objetivo' : 'Your goal';

  String editProfileImageSelectionError(String error) => _isSpanishEditProfile
      ? 'Error al seleccionar imagen: $error'
      : 'Error selecting image: $error';

  String permissionMessageFor(AppPermission permission) {
    switch (permission) {
      case AppPermission.camera:
        return _isSpanishEditProfile
            ? 'Permite el acceso a la cámara para actualizar tu foto de perfil.'
            : 'Allow camera access to update your profile photo.';
      case AppPermission.photos:
        return _isSpanishEditProfile
            ? 'Permite el acceso a la fototeca para elegir tu foto de perfil.'
            : 'Allow photo library access to choose your profile photo.';
      case AppPermission.notifications:
        return _isSpanishEditProfile
            ? 'Permite las notificaciones para recibir recordatorios de Rutio.'
            : 'Allow notifications to receive Rutio reminders.';
    }
  }

  String permissionSettingsMessageFor(AppPermission permission) {
    switch (permission) {
      case AppPermission.camera:
        return _isSpanishEditProfile
            ? 'Activa la cámara en Ajustes para actualizar tu foto de perfil.'
            : 'Enable camera access in Settings to update your profile photo.';
      case AppPermission.photos:
        return _isSpanishEditProfile
            ? 'Activa la fototeca en Ajustes para elegir tu foto de perfil.'
            : 'Enable photo library access in Settings to choose your profile photo.';
      case AppPermission.notifications:
        return _isSpanishEditProfile
            ? 'Activa las notificaciones en Ajustes para recibir recordatorios de Rutio.'
            : 'Enable notifications in Settings to receive Rutio reminders.';
    }
  }

  String get editProfileSaveSuccess => _isSpanishEditProfile
      ? 'Perfil actualizado correctamente'
      : 'Profile updated successfully';

  String editProfileSaveError(String error) => _isSpanishEditProfile
      ? 'Error al guardar: $error'
      : 'Error while saving: $error';

  String get editProfileDiscardChangesTitle =>
      _isSpanishEditProfile ? '\u00bfDescartar cambios?' : 'Discard changes?';

  String get editProfileDiscardChangesBody => _isSpanishEditProfile
      ? 'Tienes cambios sin guardar. \u00bfEst\u00e1s seguro de que quieres salir?'
      : 'You have unsaved changes. Are you sure you want to leave?';

  String get editProfileDiscardChangesAction =>
      _isSpanishEditProfile ? 'Descartar' : 'Discard';

  String get editProfileCropTitle =>
      _isSpanishEditProfile ? 'Recortar' : 'Crop';

  String get editProfileStatLevel => _isSpanishEditProfile ? 'Nivel' : 'Level';

  String get editProfileStatXp => 'XP';

  String get editProfileStatCoins =>
      _isSpanishEditProfile ? 'Monedas' : 'Coins';

  String get editProfileNameLabel => _isSpanishEditProfile ? 'Nombre' : 'Name';

  String get editProfileNameHint => _isSpanishEditProfile
      ? 'C\u00f3mo quieres que te vean'
      : 'How do you want to be seen';

  String get editProfileNameRequired =>
      _isSpanishEditProfile ? 'El nombre es obligatorio' : 'Name is required';

  String get editProfileNameMinLength => _isSpanishEditProfile
      ? 'M\u00ednimo 2 caracteres'
      : 'Minimum 2 characters';

  String get editProfileBioLabel => 'Bio';

  String get editProfileBioHint => _isSpanishEditProfile
      ? 'Cu\u00e9ntanos un poco sobre ti...'
      : 'Tell us a little about yourself...';

  String get editProfileGoalLabel =>
      _isSpanishEditProfile ? 'Objetivo' : 'Goal';

  String get editProfileGoalHint => _isSpanishEditProfile
      ? 'Qu\u00e9 quieres conseguir con Rutio'
      : 'What do you want to achieve with Rutio';

  String get editProfileChangePhoto =>
      _isSpanishEditProfile ? 'Cambiar foto de perfil' : 'Change profile photo';

  String get editProfileAddPhoto => _isSpanishEditProfile
      ? 'A\u00f1adir foto de perfil'
      : 'Add profile photo';
}

extension AppLocalizationsArchivedHabitsX on AppLocalizations {
  bool get _isSpanishArchivedHabits =>
      localeName.toLowerCase().startsWith('es');

  String get archivedHabitsTitle =>
      _isSpanishArchivedHabits ? 'H\u00e1bitos archivados' : 'Archived habits';

  String get archivedHabitsEmpty => _isSpanishArchivedHabits
      ? 'No tienes h\u00e1bitos archivados.'
      : "You don't have any archived habits.";

  String archivedHabitsFamilyLabel(String family) =>
      _isSpanishArchivedHabits ? 'Familia: $family' : 'Family: $family';

  String get archivedHabitsRestoreTooltip =>
      _isSpanishArchivedHabits ? 'Restaurar' : 'Restore';

  String get archivedHabitsDeleteTooltip =>
      _isSpanishArchivedHabits ? 'Eliminar' : 'Delete';

  String get archivedHabitsDeleteTitle =>
      _isSpanishArchivedHabits ? 'Eliminar h\u00e1bito' : 'Delete habit';

  String get archivedHabitsDeleteBody => _isSpanishArchivedHabits
      ? '\u00bfSeguro que quieres eliminar este h\u00e1bito?\n\nSe eliminar\u00e1 tambi\u00e9n su historial.'
      : 'Are you sure you want to delete this habit?\n\nIts history will also be deleted.';
}

extension AppLocalizationsHabitDetailX on AppLocalizations {
  bool get _isSpanishHabitDetail => localeName.toLowerCase().startsWith('es');

  String get habitDetailFallbackTitle =>
      _isSpanishHabitDetail ? 'H\u00e1bito' : 'Habit';

  String get habitDetailSaved =>
      _isSpanishHabitDetail ? 'Cambios guardados' : 'Changes saved';

  String get habitDetailDeleteTitle =>
      _isSpanishHabitDetail ? 'Eliminar h\u00e1bito' : 'Delete habit';

  String get habitDetailDeleteBody => _isSpanishHabitDetail
      ? 'Se borrar\u00e1 el h\u00e1bito y su historial. Esta acci\u00f3n no se puede deshacer.'
      : 'The habit and its history will be deleted. This action cannot be undone.';

  String get habitDetailArchiveAction =>
      _isSpanishHabitDetail ? 'Archivar h\u00e1bito' : 'Archive habit';

  String get habitDetailDeleteAction =>
      _isSpanishHabitDetail ? 'Eliminar h\u00e1bito' : 'Delete habit';

  String get habitDetailMoreOptionsTooltip =>
      _isSpanishHabitDetail ? 'M\u00e1s opciones' : 'More options';

  String get habitDetailEditTab => _isSpanishHabitDetail ? 'Editar' : 'Edit';

  String get habitDetailStatsTab =>
      _isSpanishHabitDetail ? 'Estad\u00edsticas' : 'Statistics';
}

extension AppLocalizationsArchiveHabitTileX on AppLocalizations {
  bool get _isSpanishArchiveHabitTile =>
      localeName.toLowerCase().startsWith('es');

  String get archiveHabitTileTitle =>
      _isSpanishArchiveHabitTile ? 'Archivar h\u00e1bito' : 'Archive habit';

  String get archiveHabitTileArchivedSubtitle => _isSpanishArchiveHabitTile
      ? 'Este h\u00e1bito est\u00e1 archivado (no aparecer\u00e1 en la lista principal).'
      : 'This habit is archived (it will not appear in the main list).';

  String get archiveHabitTileActiveSubtitle => _isSpanishArchiveHabitTile
      ? 'Oculta este h\u00e1bito de la lista principal sin borrarlo.'
      : 'Hide this habit from the main list without deleting it.';

  String get archiveHabitTileConfirmTitle =>
      _isSpanishArchiveHabitTile ? 'Archivar h\u00e1bito' : 'Archive habit';

  String get archiveHabitTileConfirmBody => _isSpanishArchiveHabitTile
      ? '\u00bfQuieres archivar este h\u00e1bito? Podr\u00e1s recuperarlo m\u00e1s adelante.'
      : 'Do you want to archive this habit? You can recover it later.';

  String get archiveHabitTileConfirmAction =>
      _isSpanishArchiveHabitTile ? 'Archivar' : 'Archive';
}

extension AppLocalizationsEditHabitX on AppLocalizations {
  bool get _isSpanishEditHabit => localeName.toLowerCase().startsWith('es');

  String get editHabitSaveChanges =>
      _isSpanishEditHabit ? 'Guardar cambios' : 'Save changes';

  String get editHabitSaving =>
      _isSpanishEditHabit ? 'Guardando...' : 'Saving...';

  String get editHabitNotificationPermissionDenied => _isSpanishEditHabit
      ? 'Permisos de notificacion denegados.'
      : 'Notification permissions denied.';

  String get editHabitDailyGoalDialogTitle =>
      _isSpanishEditHabit ? 'Meta diaria' : 'Daily goal';

  String get editHabitDailyGoalDialogSubtitle => _isSpanishEditHabit
      ? 'Escribe el numero objetivo.'
      : 'Enter the target number.';

  String get editHabitCounterStepDialogTitle =>
      _isSpanishEditHabit ? 'Incremento' : 'Increment';

  String get editHabitCounterStepDialogSubtitle => _isSpanishEditHabit
      ? 'Cada cuanto aumenta el contador.'
      : 'How much the counter increases each tap.';

  String get editHabitTimesPerWeekDialogTitle =>
      _isSpanishEditHabit ? 'Veces por semana' : 'Times per week';

  String get editHabitTimesPerWeekDialogSubtitle => _isSpanishEditHabit
      ? 'Puedes superarlo durante la semana.'
      : 'You can go over it during the week.';

  String get editHabitSectionIdentity =>
      _isSpanishEditHabit ? 'Identidad' : 'Identity';

  String get editHabitSectionCategory =>
      _isSpanishEditHabit ? 'Categoria' : 'Category';

  String get editHabitSectionTracking =>
      _isSpanishEditHabit ? 'Como lo mides?' : 'How do you track it?';

  String get editHabitSectionFrequency =>
      _isSpanishEditHabit ? 'Frecuencia' : 'Frequency';

  String get editHabitSectionReminder =>
      _isSpanishEditHabit ? 'Recordatorio' : 'Reminder';

  String get editHabitSectionDetails =>
      _isSpanishEditHabit ? 'Detalles' : 'Details';

  String get editHabitTitleHint => _isSpanishEditHabit
      ? 'Ej: Meditar cada manana'
      : 'Ex: Meditate every morning';

  String get editHabitTrackingCheckTitle =>
      _isSpanishEditHabit ? 'Si o no' : 'Yes or no';

  String get editHabitTrackingCheckSubtitle =>
      _isSpanishEditHabit ? 'Lo hice o no lo hice' : 'I did it or I did not';

  String get editHabitTrackingCountTitle =>
      _isSpanishEditHabit ? 'Contador' : 'Counter';

  String get editHabitTrackingCountSubtitle => _isSpanishEditHabit
      ? 'Vasos, minutos, paginas...'
      : 'Glasses, minutes, pages...';

  String get editHabitDailyGoalSection =>
      _isSpanishEditHabit ? 'Meta diaria' : 'Daily goal';

  String get editHabitRepetitionsTitle =>
      _isSpanishEditHabit ? 'Repeticiones' : 'Repetitions';

  String get editHabitRepetitionsSubtitle =>
      _isSpanishEditHabit ? 'Cuantas veces al dia?' : 'How many times per day?';

  String get editHabitUnitHint => _isSpanishEditHabit
      ? 'Unidad (ej: vasos, km...)'
      : 'Unit (ex: glasses, km...)';

  String get editHabitCounterStepTitle =>
      _isSpanishEditHabit ? 'Incremento' : 'Increment';

  String get editHabitCounterStepSubtitle => _isSpanishEditHabit
      ? 'Cuanto aumenta cada toque.'
      : 'How much each tap increases it.';

  String get editHabitFrequencyDaily =>
      _isSpanishEditHabit ? 'Cada dia' : 'Every day';

  String get editHabitFrequencySpecificDays =>
      _isSpanishEditHabit ? 'Dias concretos' : 'Specific days';

  String get editHabitFrequencyTimesPerWeek =>
      _isSpanishEditHabit ? 'X veces / semana' : 'X times / week';

  String get editHabitWeeklyGoalTitle =>
      _isSpanishEditHabit ? 'Objetivo semanal' : 'Weekly goal';

  String get editHabitWeeklyGoalSubtitle => _isSpanishEditHabit
      ? 'Marca cuantas veces quieres completarlo.'
      : 'Choose how many times you want to complete it.';

  String get editHabitReminderDailyTitle =>
      _isSpanishEditHabit ? 'Notificacion diaria' : 'Daily notification';

  String get editHabitReminderDailySubtitle => _isSpanishEditHabit
      ? 'Elige cuando quieres que te avise'
      : 'Choose when you want to be reminded';

  String get editHabitDescriptionHint =>
      _isSpanishEditHabit ? 'Descripcion breve' : 'Short description';

  String get editHabitNotesHint => _isSpanishEditHabit
      ? 'Notas o contexto adicional'
      : 'Notes or additional context';

  String get editHabitUnitPickerTitle =>
      _isSpanishEditHabit ? 'Unidad' : 'Unit';

  String get editHabitUnitPickerSubtitle => _isSpanishEditHabit
      ? 'Elige una sugerencia o escribe una personalizada.'
      : 'Choose a suggestion or type a custom one.';

  String get editHabitUnitPickerAction =>
      _isSpanishEditHabit ? 'Usar unidad' : 'Use unit';

  List<String> get editHabitSuggestedUnits => <String>[
        _isSpanishEditHabit ? 'vasos' : 'glasses',
        _isSpanishEditHabit ? 'minutos' : 'minutes',
        'km',
        _isSpanishEditHabit ? 'paginas' : 'pages',
        _isSpanishEditHabit ? 'pasos' : 'steps',
        _isSpanishEditHabit ? 'repeticiones' : 'reps',
        _isSpanishEditHabit ? 'horas' : 'hours',
      ];
}

extension AppLocalizationsCreateHabitX on AppLocalizations {
  bool get _isSpanishCreateHabit => localeName.toLowerCase().startsWith('es');

  String get createHabitNewHabitTitle =>
      _isSpanishCreateHabit ? 'Nuevo habito' : 'New habit';

  String get createHabitSaveHabit =>
      _isSpanishCreateHabit ? 'Guardar habito' : 'Save habit';

  String get createHabitSaved => _isSpanishCreateHabit ? 'Guardado' : 'Saved';
}

extension AppLocalizationsHomeSharedX on AppLocalizations {
  bool get _isSpanishHomeShared => localeName.toLowerCase().startsWith('es');

  String get homeAddFabTooltip =>
      _isSpanishHomeShared ? 'Crear hábito' : 'Create habit';
}

extension AppLocalizationsEmojiPickerX on AppLocalizations {
  bool get _isSpanishEmojiPicker => localeName.toLowerCase().startsWith('es');

  String get emojiPickerTitle =>
      _isSpanishEmojiPicker ? 'Selecciona un emoji' : 'Select an emoji';

  String emojiPickerCurrent(String emoji) =>
      _isSpanishEmojiPicker ? 'Actual: $emoji' : 'Current: $emoji';

  String get emojiPickerBrowseSubtitle => _isSpanishEmojiPicker
      ? 'Catalogo completo con categorias y busqueda'
      : 'Full catalog with categories and search';

  String get emojiPickerNoRecents => _isSpanishEmojiPicker
      ? 'Tus emojis recientes apareceran aqui'
      : 'Your recent emojis will appear here';

  String get emojiPickerSearchHint =>
      _isSpanishEmojiPicker ? 'Buscar emoji' : 'Search emoji';
}

extension AppLocalizationsMonthlyX on AppLocalizations {
  bool get _isSpanishMonthly => localeName.toLowerCase().startsWith('es');

  String get monthlyDefaultUsername => _isSpanishMonthly ? 'Usuario' : 'User';

  String get monthlyEmptyFilteredMessage => _isSpanishMonthly
      ? 'No hay h\u00e1bitos para mostrar en este filtro.'
      : 'There are no habits to show for this filter.';

  String monthlyElapsedDaysWeek(int elapsed, int week) => _isSpanishMonthly
      ? '$elapsed d\u00edas transcurridos \u00b7 semana $week'
      : '$elapsed days elapsed \u00b7 week $week';

  String monthlyFilterSummaryFamily(String family) =>
      _isSpanishMonthly ? 'Familia: $family' : 'Family: $family';

  String monthlyFilterSummaryHabit(String habit) =>
      _isSpanishMonthly ? 'H\u00e1bito: $habit' : 'Habit: $habit';

  String get monthlyFilterSummaryAll =>
      _isSpanishMonthly ? 'Todos los h\u00e1bitos' : 'All habits';

  String get monthlyFiltersTooltip => _isSpanishMonthly ? 'Filtros' : 'Filters';

  String get monthlyResetTooltip => _isSpanishMonthly ? 'Restablecer' : 'Reset';

  String get monthlyFiltersTitle => _isSpanishMonthly ? 'Filtros' : 'Filters';

  String get monthlyResetAction => _isSpanishMonthly ? 'Restablecer' : 'Reset';

  String get monthlyFilterModeAll => _isSpanishMonthly ? 'Todos' : 'All';

  String get monthlyFilterModeFamily =>
      _isSpanishMonthly ? 'Familia' : 'Family';

  String get monthlyFilterModeHabit =>
      _isSpanishMonthly ? 'H\u00e1bito' : 'Habit';

  String get monthlyApplyAction => _isSpanishMonthly ? 'Aplicar' : 'Apply';

  String get monthlySelectHabitLabel =>
      _isSpanishMonthly ? 'Selecciona un h\u00e1bito' : 'Select a habit';

  String get monthlyHabitSelectorTitle =>
      _isSpanishMonthly ? 'VER H\u00c1BITO' : 'VIEW HABIT';

  String get monthlyHabitFallbackTitle =>
      _isSpanishMonthly ? 'H\u00e1bito' : 'Habit';

  String get monthlyStatMonthLabel => _isSpanishMonthly ? 'MES' : 'MONTH';

  String get monthlyStatStreakLabel => _isSpanishMonthly ? 'RACHA' : 'STREAK';

  String get monthlyStatHabitsLabel =>
      _isSpanishMonthly ? 'H\u00c1BITOS' : 'HABITS';

  String monthlyDaysLabelCompat(int count) => _isSpanishMonthly
      ? '$count d\u00eda${count == 1 ? '' : 's'}'
      : '$count day${count == 1 ? '' : 's'}';

  String get monthlyCurrentStreakSoft =>
      _isSpanishMonthly ? 'racha actual' : 'current streak';

  String get monthlyBestStreakSoft =>
      _isSpanishMonthly ? 'mejor racha' : 'best streak';

  String get monthlySelectionToday => _isSpanishMonthly ? 'Hoy' : 'Today';

  String get monthlySelectionDone =>
      _isSpanishMonthly ? 'Completado' : 'Completed';

  String get monthlySelectionSkipped =>
      _isSpanishMonthly ? 'Saltado' : 'Skipped';

  String get monthlySelectionPending =>
      _isSpanishMonthly ? 'Pendiente' : 'Pending';

  String get monthlySelectionFuture => _isSpanishMonthly ? 'Futuro' : 'Future';

  String get monthlySelectionUnscheduled =>
      _isSpanishMonthly ? 'Sin programar' : 'Unscheduled';

  String get monthlySelectionSelected =>
      _isSpanishMonthly ? 'Seleccionado' : 'Selected';

  String monthlySelectionLabel(int day, int month, String state) =>
      '$day/$month \u00b7 $state';

  String get monthlyCurrentMonthTooltip =>
      _isSpanishMonthly ? 'Ir a este mes' : 'Go to this month';

  String get monthlyMenuTooltip => _isSpanishMonthly ? 'Men\u00fa' : 'Menu';

  String monthlyMonthTitle(DateTime month) {
    final raw = monthFull(month.month);
    final capitalized =
        raw.isEmpty ? raw : '${raw[0].toUpperCase()}${raw.substring(1)}';
    return '$capitalized ${month.year}';
  }
}

extension AppLocalizationsWeeklyViewMenuX on AppLocalizations {
  bool get _isSpanishWeeklyViewMenu =>
      localeName.toLowerCase().startsWith('es');

  String get weeklyViewMenuTitle =>
      _isSpanishWeeklyViewMenu ? 'Cambiar vista' : 'Change view';

  String get weeklyViewMenuDailyTitle =>
      _isSpanishWeeklyViewMenu ? 'Vista diaria' : 'Daily view';

  String get weeklyViewMenuDailySubtitle =>
      _isSpanishWeeklyViewMenu ? 'Ver hábitos de hoy' : "See today's habits";

  String get weeklyViewMenuWeeklyTitle =>
      _isSpanishWeeklyViewMenu ? 'Vista semanal' : 'Weekly view';

  String get weeklyViewMenuWeeklySubtitle =>
      _isSpanishWeeklyViewMenu ? 'Actual' : 'Current';

  String get weeklyViewMenuMonthlyTitle =>
      _isSpanishWeeklyViewMenu ? 'Vista mensual' : 'Monthly view';

  String get weeklyViewMenuMonthlySubtitle => _isSpanishWeeklyViewMenu
      ? 'Ver progreso del mes'
      : 'See this month progress';
}

extension AppLocalizationsWeeklySharedX on AppLocalizations {
  bool get _isSpanishWeeklyShared => localeName.toLowerCase().startsWith('es');

  String get weeklyInvalidNumberMessage => _isSpanishWeeklyShared
      ? 'Introduce un número válido.'
      : 'Enter a valid number.';
}

extension AppLocalizationsHabitStatsX on AppLocalizations {
  bool get _isSpanishHabitStats => localeName.toLowerCase().startsWith('es');

  String get habitStatsTitle =>
      _isSpanishHabitStats ? 'Estadisticas' : 'Statistics';

  String get habitStatsEmpty => _isSpanishHabitStats
      ? 'No hay habitos para mostrar.'
      : 'There are no habits to show.';

  String get habitStatsMetricCompleted =>
      _isSpanishHabitStats ? 'Completado' : 'Completed';

  String habitStatsMetricCompletionDescription(int done, int total) =>
      _isSpanishHabitStats ? '$done/$total dias' : '$done/$total days';

  String get habitStatsMetricConsistency =>
      _isSpanishHabitStats ? 'Consistencia' : 'Consistency';

  String habitStatsMetricConsistencyDescription(int window) =>
      _isSpanishHabitStats ? 'Ultimos $window dias' : 'Last $window days';

  String get habitStatsMetricBestStreak =>
      _isSpanishHabitStats ? 'Mejor racha' : 'Best streak';

  String get habitStatsMetricPersonalBest =>
      _isSpanishHabitStats ? 'Record personal' : 'Personal best';

  String get habitStatsMetricTotalDone =>
      _isSpanishHabitStats ? 'Total hechos' : 'Total done';

  String get habitStatsMetricHistoricRecords =>
      _isSpanishHabitStats ? 'Historico (registros)' : 'Historical records';

  String get habitStatsChartWeekTitle =>
      _isSpanishHabitStats ? 'Semana' : 'Week';

  String get habitStatsChartLastFourWeeksTitle =>
      _isSpanishHabitStats ? 'Ultimas 4 semanas' : 'Last 4 weeks';

  String get habitStatsChartWeekSubtitle =>
      _isSpanishHabitStats ? 'Completado por dia' : 'Completed by day';

  String get habitStatsChartWeeksSubtitle => _isSpanishHabitStats
      ? 'Completado agregado por semana'
      : 'Completed aggregated by week';

  String get habitStatsNextMilestone =>
      _isSpanishHabitStats ? 'Siguiente hito' : 'Next milestone';

  String get habitStatsWeeklyComparisonTitle =>
      _isSpanishHabitStats ? 'Comparacion semanal' : 'Weekly comparison';

  String get habitStatsWeeklyComparisonSubtitle => _isSpanishHabitStats
      ? 'Esta semana vs la anterior'
      : 'This week vs last week';

  String get habitStatsBestTimeSectionTitle => _isSpanishHabitStats
      ? 'Cuando lo cumples mejor?'
      : 'When do you complete it best?';

  String get habitStatsBestTimeSectionSubtitle => _isSpanishHabitStats
      ? 'Basado en tus registros, tus momentos mas consistentes'
      : 'Based on your logs, your most consistent moments';

  String get habitStatsMonthCalendarTitle =>
      _isSpanishHabitStats ? 'Calendario del mes' : 'Monthly calendar';

  String get habitStatsTabSummaryTitle =>
      _isSpanishHabitStats ? 'Resumen' : 'Summary';

  String habitStatsTabLastDaysTitle(int days) =>
      _isSpanishHabitStats ? '\u00daltimos $days d\u00edas' : 'Last $days days';

  String get habitStatsTabAchievementsUnlocked =>
      _isSpanishHabitStats ? 'Logros desbloqueados' : 'Achievements unlocked';

  String get habitStatsTabCurrentStreakTitle =>
      _isSpanishHabitStats ? 'Racha actual' : 'Current streak';

  String habitStatsTabDayUnit(int count) => _isSpanishHabitStats
      ? (count == 1 ? 'd\u00eda' : 'd\u00edas')
      : (count == 1 ? 'day' : 'days');

  String get habitStatsTabTotalLabel => 'total';

  String habitStatsTabCompletionWindow(int done, int total) =>
      _isSpanishHabitStats ? '$done / $total d\u00edas' : '$done / $total days';

  String get habitStatsTabCounterHint => _isSpanishHabitStats
      ? 'Cuenta el n\u00famero de veces completado cada d\u00eda'
      : 'Counts how many times you completed it each day';

  String get habitStatsTabCheckHint => _isSpanishHabitStats
      ? 'D\u00edas en los que completaste este h\u00e1bito'
      : 'Days when you completed this habit';

  String get habitStatsTabFireStreakTitle =>
      _isSpanishHabitStats ? 'Racha de fuego' : 'Fire streak';

  String habitStatsTabStreakInARow(int days) =>
      _isSpanishHabitStats ? '$days d\u00edas seguidos' : '$days days in a row';

  String get habitStatsTabCentennialTitle =>
      _isSpanishHabitStats ? '\u00a1Centenario!' : 'Centennial!';

  String get habitStatsTabHalfCenturyTitle =>
      _isSpanishHabitStats ? 'Medio centenar' : 'Half century';

  String habitStatsTabCompletedCount(int count) =>
      _isSpanishHabitStats ? '$count completados' : '$count completed';

  String get habitStatsTabMaxConsistencyTitle =>
      _isSpanishHabitStats ? 'Consistencia m\u00e1xima' : 'Peak consistency';

  String habitStatsTabLast30DaysPercent(int percent) => _isSpanishHabitStats
      ? '$percent% \u00faltimos 30 d\u00edas'
      : '$percent% in the last 30 days';

  String get habitStatsTabLegendaryRecordTitle =>
      _isSpanishHabitStats ? 'R\u00e9cord legendario' : 'Legendary record';

  String habitStatsTabRecordStreak(int days) =>
      _isSpanishHabitStats ? '$days d\u00edas de racha' : '$days-day streak';

  String habitStatsTabWeeklyDelta(int delta) {
    if (delta == 0) {
      return _isSpanishHabitStats
          ? 'Igual que semana anterior'
          : 'Same as last week';
    }

    final prefix = delta > 0 ? '+' : '';
    return _isSpanishHabitStats
        ? '$prefix$delta vs semana anterior'
        : '$prefix$delta vs last week';
  }

  String habitStatsWeekShort(int weekNumber) =>
      _isSpanishHabitStats ? 'S$weekNumber' : 'W$weekNumber';

  String get habitStatsHabitFallbackTitle =>
      _isSpanishHabitStats ? 'Habito' : 'Habit';

  String get habitStatsPeriodWeek => _isSpanishHabitStats ? 'Semana' : 'Week';

  String get habitStatsPeriodMonth => _isSpanishHabitStats ? 'Mes' : 'Month';

  String get habitStatsPeriodThreeMonths =>
      _isSpanishHabitStats ? '3 meses' : '3 months';

  String get habitStatsPeriodAll => _isSpanishHabitStats ? 'Todo' : 'All';

  String habitStatsDaysLabel(int count) => _isSpanishHabitStats
      ? '$count dia${count == 1 ? '' : 's'}'
      : '$count day${count == 1 ? '' : 's'}';

  String get habitStatsCurrentStreakUpper =>
      _isSpanishHabitStats ? 'RACHA ACTUAL' : 'CURRENT STREAK';

  String get habitStatsHeadlineStartToday =>
      _isSpanishHabitStats ? 'Empezamos hoy!' : 'We start today!';

  String get habitStatsHeadlineGoodStart =>
      _isSpanishHabitStats ? 'Buen inicio!' : 'Good start!';

  String get habitStatsHeadlineOnStreak =>
      _isSpanishHabitStats ? 'En racha!' : 'On a streak!';

  String habitStatsMilestoneProgress(String label, int next) =>
      _isSpanishHabitStats
          ? '$label: $next dias'
          : '$label: ${habitStatsDaysLabel(next)}';

  String get habitStatsThisWeek =>
      _isSpanishHabitStats ? 'Esta semana' : 'This week';

  String get habitStatsLastWeek =>
      _isSpanishHabitStats ? 'Semana pasada' : 'Last week';

  String habitStatsTimeSlot(String slot) {
    switch (slot) {
      case 'morning':
        return _isSpanishHabitStats ? 'manana' : 'morning';
      case 'afternoon':
        return _isSpanishHabitStats ? 'tarde' : 'afternoon';
      case 'evening':
        return _isSpanishHabitStats ? 'noche' : 'evening';
      case 'night':
        return _isSpanishHabitStats ? 'madrugada' : 'late night';
      default:
        return slot;
    }
  }

  String get habitStatsLegendLess => _isSpanishHabitStats ? 'Menos' : 'Less';

  String get habitStatsLegendMore => _isSpanishHabitStats ? 'Mas' : 'More';

  String habitStatsDayTooltip(int day) =>
      _isSpanishHabitStats ? 'Dia $day' : 'Day $day';

  String get habitStatsThisHabitFallback =>
      _isSpanishHabitStats ? 'este habito' : 'this habit';

  String get habitStatsMotivationLead =>
      _isSpanishHabitStats ? 'Llevas ' : 'You have ';

  String get habitStatsMotivationWith =>
      _isSpanishHabitStats ? ' con ' : ' with ';

  String get habitStatsMotivationAboveLead =>
      _isSpanishHabitStats ? 'estas ' : 'you are ';

  String get habitStatsMotivationAboveKeyword =>
      _isSpanishHabitStats ? 'por encima' : 'ahead';

  String get habitStatsMotivationAboveTail =>
      _isSpanishHabitStats ? ' de la semana pasada. ' : ' of last week. ';

  String get habitStatsMotivationBelowLead => _isSpanishHabitStats
      ? 'esta semana vas un poco '
      : 'this week you are a bit ';

  String get habitStatsMotivationBelowKeyword =>
      _isSpanishHabitStats ? 'por debajo' : 'behind';

  String get habitStatsMotivationBelowTail =>
      _isSpanishHabitStats ? ' de la anterior. ' : ' than the previous one. ';

  String get habitStatsMotivationEqual => _isSpanishHabitStats
      ? 'mantienes el ritmo de la semana pasada. '
      : 'you are keeping last week' 's pace. ';

  String get habitStatsMotivationStart =>
      _isSpanishHabitStats ? 'buen comienzo. ' : 'good start. ';

  String get habitStatsMotivationGoalLead => _isSpanishHabitStats
      ? 'Anticiparte te ayudara a '
      : 'Planning ahead will help you ';

  String habitStatsMotivationGoalKeyword(int days) => _isSpanishHabitStats
      ? 'llegar a los $days dias'
      : 'reach ${habitStatsDaysLabel(days)}';

  String get habitStatsMotivationKeepLead =>
      _isSpanishHabitStats ? 'Ahora toca ' : 'Now it is time to ';

  String get habitStatsMotivationKeepKeyword =>
      _isSpanishHabitStats ? 'mantener la racha' : 'keep the streak';

  String get habitStatsMotivationKeepTail =>
      _isSpanishHabitStats ? ' y consolidarlo.' : ' and make it stick.';

  String get habitStatsMotivationBestTimeLead => _isSpanishHabitStats
      ? ' Prueba a hacerlo en la '
      : ' Try doing it in the ';

  String get habitStatsMotivationBestTimeTail => _isSpanishHabitStats
      ? ', cuando sueles ser mas constante.'
      : ', when you tend to be most consistent.';
}

extension AppLocalizationsDiaryX on AppLocalizations {
  bool get _isSpanishDiary => localeName.toLowerCase().startsWith('es');

  String get diaryTitle => _isSpanishDiary ? 'Diario' : 'Diary';

  String get diaryMenuTooltip => _isSpanishDiary ? 'Menu' : 'Menu';

  String get diaryCloseSearchTooltip =>
      _isSpanishDiary ? 'Cerrar busqueda' : 'Close search';

  String get diarySearchTooltip => _isSpanishDiary ? 'Buscar' : 'Search';

  String get diaryFiltersTooltip => _isSpanishDiary ? 'Filtros' : 'Filters';

  String get diaryNewEntry => _isSpanishDiary ? 'Nueva entrada' : 'New entry';

  String get diaryEntryDeleted =>
      _isSpanishDiary ? 'Entrada eliminada' : 'Entry deleted';

  String get diaryEntrySaved =>
      _isSpanishDiary ? 'Entrada guardada' : 'Entry saved';

  String get diaryNoteSaved => _isSpanishDiary ? 'Nota guardada' : 'Note saved';

  String get diaryPinSoon =>
      _isSpanishDiary ? 'Fijar: proximamente' : 'Pin: coming soon';

  String get diaryDeleteEntryTitle =>
      _isSpanishDiary ? 'Eliminar entrada' : 'Delete entry';

  String get diaryDeleteEntryBody => _isSpanishDiary
      ? 'Seguro que quieres eliminar esta entrada?'
      : 'Are you sure you want to delete this entry?';

  String diaryEntriesCount(int count) => _isSpanishDiary
      ? '$count entrada${count == 1 ? '' : 's'}'
      : '$count entr${count == 1 ? 'y' : 'ies'}';

  String get diaryPeriodAll => _isSpanishDiary ? 'Todo' : 'All';

  String get diaryPeriodDays => _isSpanishDiary ? 'Dias' : 'Days';

  String get diaryPeriodWeeks => _isSpanishDiary ? 'Semanas' : 'Weeks';

  String get diaryPeriodMonths => _isSpanishDiary ? 'Meses' : 'Months';

  String get diarySearchHint =>
      _isSpanishDiary ? 'Buscar en tu diario...' : 'Search your diary...';

  String get diaryClearTooltip => _isSpanishDiary ? 'Borrar' : 'Clear';

  String get diarySearchScopeAll => _isSpanishDiary ? 'Todo' : 'All';

  String get diarySearchScopeHabits => _isSpanishDiary ? 'Habitos' : 'Habits';

  String get diarySearchScopePersonal =>
      _isSpanishDiary ? 'Personal' : 'Personal';

  String diaryWrittenEntriesToday(int count) => _isSpanishDiary
      ? 'Hoy escribiste $count entrada${count == 1 ? '' : 's'}'
      : 'Today you wrote $count entr${count == 1 ? 'y' : 'ies'}';

  String diaryEmotionalXp(int xp) =>
      _isSpanishDiary ? '+$xp XP emocional' : '+$xp emotional XP';

  String get diarySummaryEmptyTitle =>
      _isSpanishDiary ? 'Hoy aun no has escrito' : 'You have not written yet';

  String get diarySummaryEmptySubtitle => _isSpanishDiary
      ? 'Un minuto puede cambiar tu dia'
      : 'One minute can change your day';

  String get diarySummaryOneTitle =>
      _isSpanishDiary ? 'Buen comienzo' : 'Good start';

  String get diarySummaryOneSubtitle => _isSpanishDiary
      ? 'Has dado espacio a tu mente'
      : 'You made space for your mind';

  String get diarySummaryFewTitle => _isSpanishDiary
      ? 'Estas cuidando tu mundo interior'
      : 'You are caring for your inner world';

  String get diarySummaryFewSubtitle =>
      _isSpanishDiary ? 'Sigue asi' : 'Keep it up';

  String get diarySummaryManyTitle =>
      _isSpanishDiary ? 'Dia muy consciente' : 'Very mindful day';

  String get diarySummaryManySubtitle =>
      _isSpanishDiary ? 'Gran trabajo emocional' : 'Great emotional work';

  String get diaryActionEdit => _isSpanishDiary ? 'Editar' : 'Edit';

  String get diaryActionDelete => _isSpanishDiary ? 'Eliminar' : 'Delete';

  String get diaryComposerCancel =>
      _isSpanishDiary ? 'â† Cancelar' : 'â† Cancel';

  String get diaryComposerEditEntryUpper =>
      _isSpanishDiary ? 'EDITAR ENTRADA' : 'EDIT ENTRY';

  String get diaryComposerNewEntryUpper =>
      _isSpanishDiary ? 'NUEVA ENTRADA' : 'NEW ENTRY';

  String get diaryComposerMoodSectionUpper =>
      _isSpanishDiary ? 'Â¿COMO TE SENTISTE?' : 'HOW DID YOU FEEL?';

  String get diaryComposerTitleUpper => _isSpanishDiary ? 'TITULO' : 'TITLE';

  String get diaryComposerReflectionUpper =>
      _isSpanishDiary ? 'REFLEXION' : 'REFLECTION';

  String get diaryComposerTitleHint =>
      _isSpanishDiary ? 'Como resumirias hoy?' : 'How would you sum up today?';

  String get diaryComposerHabitReflectionHint => _isSpanishDiary
      ? 'Que paso hoy con tu habito? Que sentiste? Que aprendiste?'
      : 'What happened today with your habit? What did you feel? What did you learn?';

  String get diaryComposerPersonalReflectionHint => _isSpanishDiary
      ? 'Que tienes en mente? Que quieres dejar por escrito hoy?'
      : 'What is on your mind? What do you want to leave in writing today?';

  String get diaryComposerSaveChanges =>
      _isSpanishDiary ? 'Guardar cambios' : 'Save changes';

  String get diaryComposerSaveEntry =>
      _isSpanishDiary ? 'Guardar entrada' : 'Save entry';

  String get diaryComposerTypeHabit =>
      _isSpanishDiary ? 'Ligada a habito' : 'Linked to habit';

  String get diaryComposerTypePersonal =>
      _isSpanishDiary ? 'Personal' : 'Personal';

  String get diaryComposerSelectHabit =>
      _isSpanishDiary ? 'Seleccionar habito' : 'Select habit';

  String get diaryComposerTapToChooseHabit =>
      _isSpanishDiary ? 'Toca para elegir un habito' : 'Tap to choose a habit';

  String get diaryComposerWriteSomethingError => _isSpanishDiary
      ? 'Escribe algo para guardar la entrada'
      : 'Write something to save the entry';

  String get diaryComposerSelectHabitError =>
      _isSpanishDiary ? 'Selecciona un habito' : 'Select a habit';

  String get diaryComposerNoActiveHabits => _isSpanishDiary
      ? 'No hay habitos activos para seleccionar'
      : 'There are no active habits to choose from';

  String get diaryComposerSelectHabitSheetTitle =>
      _isSpanishDiary ? 'Seleccionar habito' : 'Select habit';

  String get diaryDetailScreenTitle => _isSpanishDiary ? 'Entrada' : 'Entry';

  String get diaryDetailTopHabitUpper =>
      _isSpanishDiary ? 'ENTRADA DE HABITO' : 'HABIT ENTRY';

  String get diaryDetailTopPersonalUpper =>
      _isSpanishDiary ? 'ENTRADA PERSONAL' : 'PERSONAL ENTRY';

  String get diaryDetailFallbackHabitTitle =>
      _isSpanishDiary ? 'Entrada de habito' : 'Habit entry';

  String get diaryDetailFallbackPersonalTitle =>
      _isSpanishDiary ? 'Entrada personal' : 'Personal entry';

  String get diaryDetailLeadingPersonal =>
      _isSpanishDiary ? 'Escrito personal' : 'Personal note';

  String get diaryDetailFamilyPersonal =>
      _isSpanishDiary ? 'Personal' : 'Personal';

  String get diaryDetailTypeHabit =>
      _isSpanishDiary ? 'Dia de habito' : 'Habit day';

  String get diaryDetailTypePersonal =>
      _isSpanishDiary ? 'Nota personal' : 'Personal note';

  String get diaryDetailNotesUpper => _isSpanishDiary ? 'NOTAS' : 'NOTES';

  String diaryDetailLoggedAt(String time) =>
      _isSpanishDiary ? 'Registrado a las $time' : 'Logged at $time';

  String get diaryDetailThisWeekUpper =>
      _isSpanishDiary ? 'ESTA SEMANA' : 'THIS WEEK';

  String get diaryTodayUpper => _isSpanishDiary ? 'HOY' : 'TODAY';

  String get diaryFiltersTitle => _isSpanishDiary ? 'Filtros' : 'Filters';

  String get diaryFiltersType => _isSpanishDiary ? 'Tipo' : 'Type';

  String get diaryFiltersPinnedOnly =>
      _isSpanishDiary ? 'Solo fijadas' : 'Pinned only';

  String get diaryFiltersFamily => _isSpanishDiary ? 'Familia' : 'Family';

  String get diaryFiltersApply => _isSpanishDiary ? 'Aplicar' : 'Apply';

  String diaryAfterCompleteTitle(String habitName) => _isSpanishDiary
      ? 'Habito completado: $habitName'
      : 'Habit completed: $habitName';

  String get diaryAfterCompletePrompt => _isSpanishDiary
      ? 'Quieres anadir una nota rapida?'
      : 'Do you want to add a quick note?';

  String get diaryAfterCompleteSkip => _isSpanishDiary ? 'Ahora no' : 'Not now';

  String get diaryAfterCompleteWrite => _isSpanishDiary ? 'Escribir' : 'Write';

  String get diaryGeneralFamilyName => 'General';

  String get diaryCardTypeHabitShort => _isSpanishDiary ? 'DIA' : 'DAY';

  String get diaryCardTypePersonalShort => _isSpanishDiary ? 'NOTA' : 'NOTE';

  String get diaryShowMore => _isSpanishDiary ? 'Ver mas' : 'Show more';

  String get diaryShowLess => _isSpanishDiary ? 'Ver menos' : 'Show less';

  String diaryStreakLabel(int count) => _isSpanishDiary
      ? 'Racha: $count dia${count == 1 ? '' : 's'}'
      : 'Streak: $count day${count == 1 ? '' : 's'}';

  String get diaryEmotionalStreakTitle =>
      _isSpanishDiary ? 'Racha emocional' : 'Emotional streak';

  String diaryDaysLabel(int count) => _isSpanishDiary
      ? '$count dia${count == 1 ? '' : 's'}'
      : '$count day${count == 1 ? '' : 's'}';

  String monthShort(int month) {
    switch (month) {
      case 1:
        return _isSpanishDiary ? 'Ene' : 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return _isSpanishDiary ? 'Abr' : 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return _isSpanishDiary ? 'Ago' : 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return _isSpanishDiary ? 'Dic' : 'Dec';
      default:
        return '';
    }
  }

  String weekdayFull(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return _isSpanishDiary ? 'lunes' : 'Monday';
      case DateTime.tuesday:
        return _isSpanishDiary ? 'martes' : 'Tuesday';
      case DateTime.wednesday:
        return _isSpanishDiary ? 'miercoles' : 'Wednesday';
      case DateTime.thursday:
        return _isSpanishDiary ? 'jueves' : 'Thursday';
      case DateTime.friday:
        return _isSpanishDiary ? 'viernes' : 'Friday';
      case DateTime.saturday:
        return _isSpanishDiary ? 'sabado' : 'Saturday';
      case DateTime.sunday:
        return _isSpanishDiary ? 'domingo' : 'Sunday';
      default:
        return '';
    }
  }

  String monthFull(int month) {
    switch (month) {
      case 1:
        return _isSpanishDiary ? 'enero' : 'January';
      case 2:
        return _isSpanishDiary ? 'febrero' : 'February';
      case 3:
        return _isSpanishDiary ? 'marzo' : 'March';
      case 4:
        return _isSpanishDiary ? 'abril' : 'April';
      case 5:
        return _isSpanishDiary ? 'mayo' : 'May';
      case 6:
        return _isSpanishDiary ? 'junio' : 'June';
      case 7:
        return _isSpanishDiary ? 'julio' : 'July';
      case 8:
        return _isSpanishDiary ? 'agosto' : 'August';
      case 9:
        return _isSpanishDiary ? 'septiembre' : 'September';
      case 10:
        return _isSpanishDiary ? 'octubre' : 'October';
      case 11:
        return _isSpanishDiary ? 'noviembre' : 'November';
      case 12:
        return _isSpanishDiary ? 'diciembre' : 'December';
      default:
        return '';
    }
  }

  String diaryComposerDate(DateTime date) {
    final weekday = weekdayFull(date.weekday);
    final month = monthFull(date.month);
    if (_isSpanishDiary) {
      final capitalized = weekday.isEmpty
          ? weekday
          : '${weekday[0].toUpperCase()}${weekday.substring(1)}';
      return '$capitalized, ${date.day} de $month';
    }
    return '$weekday, $month ${date.day}';
  }

  String diaryDetailDate(DateTime date) {
    final weekday = weekdayFull(date.weekday);
    final month = monthFull(date.month);
    if (_isSpanishDiary) {
      return '$weekday, ${date.day} de $month';
    }
    return '$weekday, $month ${date.day}';
  }
}

extension AppLocalizationsCatalogX on AppLocalizations {
  String familyName(String familyId) {
    switch (familyId) {
      case 'mind':
        return familyMindName;
      case 'spirit':
        return familySpiritName;
      case 'body':
        return familyBodyName;
      case 'emotional':
        return familyEmotionalName;
      case 'social':
        return familySocialName;
      case 'discipline':
        return familyDisciplineName;
      case 'professional':
        return familyProfessionalName;
      case 'personal':
        return familyPersonalName;
      default:
        return familyId;
    }
  }

  String weekdayShort(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return weekdayShortMon;
      case DateTime.tuesday:
        return weekdayShortTue;
      case DateTime.wednesday:
        return weekdayShortWed;
      case DateTime.thursday:
        return weekdayShortThu;
      case DateTime.friday:
        return weekdayShortFri;
      case DateTime.saturday:
        return weekdayShortSat;
      case DateTime.sunday:
        return weekdayShortSun;
      default:
        return '';
    }
  }

  String weekdayLetter(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return weekdayLetterMon;
      case DateTime.tuesday:
        return weekdayLetterTue;
      case DateTime.wednesday:
        return weekdayLetterWed;
      case DateTime.thursday:
        return weekdayLetterThu;
      case DateTime.friday:
        return weekdayLetterFri;
      case DateTime.saturday:
        return weekdayLetterSat;
      case DateTime.sunday:
        return weekdayLetterSun;
      default:
        return '';
    }
  }

  String habitUnitLabel(String? unit) {
    final normalized = (unit ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'times':
        return unitTimesShort;
      case 'minutes':
      case 'mins':
      case 'min':
        return unitMinutesShort;
      case 'hours':
      case 'hour':
      case 'h':
        return unitHoursShort;
      case 'pages':
      case 'page':
        return unitPagesShort;
      case 'steps':
      case 'step':
        return unitStepsShort;
      case 'km':
        return unitKilometersShort;
      case 'liters':
      case 'liter':
      case 'l':
        return unitLitersShort;
      default:
        return unit ?? '';
    }
  }

  String catalogHabitName(
    String habitId, {
    num? target,
    bool preferTemplate = false,
    String? fallback,
  }) {
    switch (habitId) {
      case 'leer_x_minutos':
        if (preferTemplate && target != null) {
          return catalogHabitLeerXMinutosTarget(_formatCatalogNumber(target));
        }
        return catalogHabitLeerXMinutos;
      case 'resolver_problema_logico':
        return catalogHabitResolverProblemaLogico;
      case 'escribir_ideas_reflexiones':
        return catalogHabitEscribirIdeasReflexiones;
      case 'estudiar_x_tiempo':
        if (preferTemplate && target != null) {
          return catalogHabitEstudiarXTiempoTarget(
              _formatCatalogNumber(target));
        }
        return catalogHabitEstudiarXTiempo;
      case 'aprender_idioma':
        return catalogHabitAprenderIdioma;
      case 'escuchar_podcast_educativo':
        return catalogHabitEscucharPodcastEducativo;
      case 'tomar_notas':
        return catalogHabitTomarNotas;
      case 'juego_mental':
        return catalogHabitJuegoMental;
      case 'practicar_escritura_creativa':
        return catalogHabitPracticarEscrituraCreativa;
      case 'repasar_notas':
        return catalogHabitRepasarNotas;
      case 'ver_documental':
        return catalogHabitVerDocumental;
      case 'meditar':
        return catalogHabitMeditar;
      case 'practicar_gratitud':
        return catalogHabitPracticarGratitud;
      case 'respiracion_consciente':
        return catalogHabitRespiracionConsciente;
      case 'reflexion_personal':
        return catalogHabitReflexionPersonal;
      case 'oracion_conexion_espiritual':
        return catalogHabitOracionConexionEspiritual;
      case 'revisar_aprendizajes_dia':
        return catalogHabitRevisarAprendizajesDia;
      case 'visualizacion_positiva':
        return catalogHabitVisualizacionPositiva;
      case 'lectura_espiritual':
        return catalogHabitLecturaEspiritual;
      case 'desconexion_digital':
        return catalogHabitDesconexionDigital;
      case 'contacto_naturaleza':
        return catalogHabitContactoNaturaleza;
      case 'tres_cosas_buenas':
        return catalogHabitTresCosasBuenas;
      case 'paseo_sin_movil':
        return catalogHabitPaseoSinMovil;
      case 'momento_para_ti':
        return catalogHabitMomentoParaTi;
      case 'hacer_ejercicio':
        return catalogHabitHacerEjercicio;
      case 'ir_gimnasio':
        return catalogHabitIrGimnasio;
      case 'caminar_pasos_km':
        if (preferTemplate && target != null) {
          return catalogHabitCaminarPasosKmTarget(_formatCatalogNumber(target));
        }
        return catalogHabitCaminarPasosKm;
      case 'comer_saludable':
        return catalogHabitComerSaludable;
      case 'beber_x_l_agua':
        if (preferTemplate && target != null) {
          return catalogHabitBeberXLAguaTarget(_formatCatalogNumber(target));
        }
        return catalogHabitBeberXLAgua;
      case 'dormir_X_horas':
        if (preferTemplate && target != null) {
          return catalogHabitDormirXHorasTarget(_formatCatalogNumber(target));
        }
        return catalogHabitDormirXHoras;
      case 'estiramientos':
        return catalogHabitEstiramientos;
      case 'evitar_ultraprocesados':
        return catalogHabitEvitarUltraprocesados;
      case 'cuidar_postura':
        return catalogHabitCuidarPostura;
      case 'rutina_manana':
        return catalogHabitRutinaManana;
      case 'rutina_noche':
        return catalogHabitRutinaNoche;
      case 'sin_alcohol':
        return catalogHabitSinAlcohol;
      case 'cardio':
        if (preferTemplate && target != null) {
          return catalogHabitCardioTarget(_formatCatalogNumber(target));
        }
        return catalogHabitCardio;
      case 'tomar_el_sol':
        return catalogHabitTomarElSol;
      case 'no_picar':
        return catalogHabitNoPicar;
      case 'ducha_fria':
        return catalogHabitDuchaFria;
      case 'hacer_cama':
        return catalogHabitHacerCama;
      case 'skincare':
        return catalogHabitSkincare;
      case 'higiene_bucal':
        return catalogHabitHigieneBucal;
      case 'tomar_suplementos':
        return catalogHabitTomarSuplementos;
      case 'hidratar_piel':
        return catalogHabitHidratarPiel;
      case 'diario_emocional':
        return catalogHabitDiarioEmocional;
      case 'identificar_emociones':
        return catalogHabitIdentificarEmociones;
      case 'gestionar_estres':
        return catalogHabitGestionarEstres;
      case 'autocompasion':
        return catalogHabitAutocompasion;
      case 'hablar_sentimientos':
        return catalogHabitHablarSentimientos;
      case 'reducir_pensamientos_negativos':
        return catalogHabitReducirPensamientosNegativos;
      case 'practicar_paciencia':
        return catalogHabitPracticarPaciencia;
      case 'momento_alegria':
        return catalogHabitMomentoAlegria;
      case 'celebrar_logro':
        return catalogHabitCelebrarLogro;
      case 'nota_animo':
        if (preferTemplate && target != null) {
          return catalogHabitNotaAnimoTarget(_formatCatalogNumber(target));
        }
        return catalogHabitNotaAnimo;
      case 'sin_pantallas_noche':
        if (preferTemplate && target != null) {
          return catalogHabitSinPantallasNocheTarget(
              _formatCatalogNumber(target));
        }
        return catalogHabitSinPantallasNoche;
      case 'hablar_ser_querido':
        return catalogHabitHablarSerQuerido;
      case 'escuchar_activamente':
        return catalogHabitEscucharActivamente;
      case 'expresar_gratitud':
        return catalogHabitExpresarGratitud;
      case 'ayudar_alguien':
        return catalogHabitAyudarAlguien;
      case 'mantener_contacto':
        return catalogHabitMantenerContacto;
      case 'compartir_experiencias':
        return catalogHabitCompartirExperiencias;
      case 'practicar_empatia':
        return catalogHabitPracticarEmpatia;
      case 'plan_social':
        return catalogHabitPlanSocial;
      case 'desconectar_redes':
        return catalogHabitDesconectarRedes;
      case 'mensaje_animo':
        return catalogHabitMensajeAnimo;
      case 'llamada_familia_amigo':
        return catalogHabitLlamadaFamiliaAmigo;
      case 'planificar_dia':
        return catalogHabitPlanificarDia;
      case 'cumplir_rutina':
        return catalogHabitCumplirRutina;
      case 'revisar_objetivos':
        return catalogHabitRevisarObjetivos;
      case 'evitar_procrastinacion':
        return catalogHabitEvitarProcrastinacion;
      case 'tarea_dificil':
        return catalogHabitTareaDificil;
      case 'priorizar_importante':
        return catalogHabitPriorizarImportante;
      case 'dejar_fumar':
        return catalogHabitDejarFumar;
      case 'sin_redes_sociales':
        if (preferTemplate && target != null) {
          return catalogHabitSinRedesSocialesTarget(
              _formatCatalogNumber(target));
        }
        return catalogHabitSinRedesSociales;
      case 'madrugar':
        return catalogHabitMadrugar;
      case 'revisar_fin_dia':
        return catalogHabitRevisarFinDia;
      case 'apagar_movil':
        return catalogHabitApagarMovil;
      case 'sin_compras_impulsivas':
        return catalogHabitSinComprasImpulsivas;
      case 'preparar_ropa':
        return catalogHabitPrepararRopa;
      case 'trabajo_profundo':
        if (preferTemplate && target != null) {
          return catalogHabitTrabajoProfundoTarget(
              _formatCatalogNumber(target));
        }
        return catalogHabitTrabajoProfundo;
      case 'habilidad_laboral':
        return catalogHabitHabilidadLaboral;
      case 'organizar_tareas':
        return catalogHabitOrganizarTareas;
      case 'revisar_rendimiento':
        return catalogHabitRevisarRendimiento;
      case 'networking':
        return catalogHabitNetworking;
      case 'formacion_profesional':
        if (preferTemplate && target != null) {
          return catalogHabitFormacionProfesionalTarget(
              _formatCatalogNumber(target));
        }
        return catalogHabitFormacionProfesional;
      case 'responder_emails':
        return catalogHabitResponderEmails;
      case 'proyecto_personal':
        return catalogHabitProyectoPersonal;
      case 'leer_sector':
        return catalogHabitLeerSector;
      case 'pomodoro':
        if (preferTemplate && target != null) {
          return catalogHabitPomodoroTarget(_formatCatalogNumber(target));
        }
        return catalogHabitPomodoro;
      case 'truco_nuevo':
        return catalogHabitTrucoNuevo;
      default:
        return fallback ?? habitId;
    }
  }
}

String _formatCatalogNumber(num value) {
  if (value % 1 == 0) {
    return value.toInt().toString();
  }
  return value.toString();
}
