import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/screens/todo/helpers/todo_date_formatter.dart';
import 'package:rutio/screens/todo/helpers/todo_style_resolver.dart';
import 'package:rutio/screens/todo/models/todo_item.dart';
import 'package:rutio/screens/todo/models/todo_priority.dart';
import 'package:rutio/screens/todo/models/todo_type.dart';
import 'package:rutio/utils/app_theme.dart';

class CreateTodoScreen extends StatefulWidget {
  const CreateTodoScreen({
    super.key,
    this.initialItem,
    this.isEditing = false,
  });

  final TodoItem? initialItem;
  final bool isEditing;

  @override
  State<CreateTodoScreen> createState() => _CreateTodoScreenState();
}

class _CreateTodoScreenState extends State<CreateTodoScreen> {
  static const Color _sheetBackground = Color(0xFFF5EDE0);
  static const Color _sheetBorder = Color(0x1FB8895A);
  static const Color _segmentedBackground = Color(0x1AB8895A);
  static const Color _mutedText = Color(0xFFC4B09A);

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;

  TodoType _selectedType = TodoType.free;
  TodoPriority _selectedPriority = TodoPriority.normal;
  String _selectedCategoryId = TodoStyleResolver.categoryIds.first;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool get _canSave => _titleController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController()..addListener(_handleChange);
    _descriptionController = TextEditingController();
    _notesController = TextEditingController();
    _seedInitialValues();
  }

  @override
  void dispose() {
    _titleController
      ..removeListener(_handleChange)
      ..dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: TodoStyleResolver.sheetChrome,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(34),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: _sheetBackground,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    10,
                    20,
                    20 + bottomSafeArea + bottomInset,
                  ),
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _mutedText.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildNavBar(context),
                    const SizedBox(height: 14),
                    _buildSegmentedToggle(context),
                    const SizedBox(height: 14),
                    _buildTextCard(context),
                    const SizedBox(height: 14),
                    _buildSectionLabel(l10n.todoWhen),
                    const SizedBox(height: 8),
                    _buildWhenCard(context),
                    const SizedBox(height: 14),
                    _buildSectionLabel(l10n.todoPriority),
                    const SizedBox(height: 8),
                    _buildPriorityCard(context),
                    const SizedBox(height: 14),
                    _buildSectionLabel(l10n.todoCategory),
                    const SizedBox(height: 8),
                    _buildCategoryCard(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavBar(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      children: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          style: TextButton.styleFrom(
            foregroundColor: TodoStyleResolver.accentSoft,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            textStyle: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          child: Text(l10n.todoCancel),
        ),
        Expanded(
          child: Text(
            widget.isEditing ? l10n.todoEditTitle : l10n.todoCreateTitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.authTitle.copyWith(
              fontSize: 18,
              letterSpacing: 0.2,
              color: TodoStyleResolver.textPrimary,
            ),
          ),
        ),
        TextButton(
          onPressed: _canSave ? _save : null,
          style: TextButton.styleFrom(
            foregroundColor: _mutedText,
            disabledForegroundColor: _mutedText,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            textStyle: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          child: Text(l10n.todoSave),
        ),
      ],
    );
  }

  Widget _buildSegmentedToggle(BuildContext context) {
    final l10n = context.l10n;

    Widget segment(TodoType type) {
      final isSelected = type == _selectedType;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _selectedType = type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? TodoStyleResolver.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              boxShadow: isSelected
                  ? <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              TodoStyleResolver.typeLabel(l10n, type),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : TodoStyleResolver.accentSoft,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _segmentedBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          segment(TodoType.free),
          segment(TodoType.linkedHabit),
        ],
      ),
    );
  }

  Widget _buildTextCard(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: <Widget>[
          CupertinoTextField.borderless(
            controller: _titleController,
            minLines: 1,
            maxLines: 3,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            placeholder: l10n.todoWhatNeedToDo,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: TodoStyleResolver.textPrimary,
            ),
            placeholderStyle: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _mutedText,
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: _sheetBorder,
          ),
          CupertinoTextField.borderless(
            controller: _descriptionController,
            minLines: 2,
            maxLines: 4,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            placeholder: l10n.todoDescriptionOptional,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: TodoStyleResolver.textPrimary.withValues(alpha: 0.82),
            ),
            placeholderStyle: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: _mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhenCard(BuildContext context) {
    final l10n = context.l10n;
    final dateValue = _selectedDate == null
        ? l10n.todoSelect
        : TodoDateFormatter.shortDate(context, _selectedDate!);
    final timeValue =
        _selectedTime == null ? l10n.todoNoTime : _formatSelectedTime(context);

    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: <Widget>[
          _CreateTodoInfoRow(
            icon: CupertinoIcons.calendar,
            label: l10n.todoDate,
            value: dateValue,
            onTap: _pickDate,
          ),
          _rowDivider(),
          _CreateTodoInfoRow(
            icon: CupertinoIcons.time,
            label: l10n.todoTime,
            value: timeValue,
            onTap: _pickTime,
          ),
          _rowDivider(),
          _CreateTodoInfoRow(
            icon: CupertinoIcons.bell,
            label: _isSpanish(context) ? 'Recordatorio' : 'Reminder',
            value: _isSpanish(context) ? 'Ninguno' : 'None',
            onTap: _showReminderSoon,
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityCard(BuildContext context) {
    final priorities = <TodoPriority>[
      TodoPriority.normal,
      TodoPriority.high,
      TodoPriority.urgent,
    ];

    return Container(
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            _RowIconBox(icon: CupertinoIcons.star),
            const SizedBox(width: 10),
            Text(
              context.l10n.todoPriority,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: TodoStyleResolver.textPrimary,
              ),
            ),
            const Spacer(),
            Row(
              children: priorities
                  .map(
                    (priority) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _PriorityDot(
                        priority: priority,
                        selected: _selectedPriority == priority,
                        onTap: () =>
                            setState(() => _selectedPriority = priority),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: _cardDecoration(),
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: TodoStyleResolver.categoryIds.map((categoryId) {
          final isSelected = categoryId == _selectedCategoryId;
          final color = TodoStyleResolver.categoryColor(categoryId);

          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryId = categoryId),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: isSelected ? 0.85 : 0.50),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : _sheetBorder,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    TodoStyleResolver.categoryName(context, categoryId),
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: isSelected ? color : TodoStyleResolver.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'DMSans',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 1,
          color: TodoStyleResolver.accentSoft,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _sheetBorder),
    );
  }

  Widget _rowDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: _sheetBorder,
    );
  }

  bool _isSpanish(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'es';
  }

  void _handleChange() {
    setState(() {});
  }

  void _seedInitialValues() {
    final item = widget.initialItem;
    if (item == null) return;

    _titleController.text = item.title;
    _descriptionController.text = item.description;
    _notesController.text = item.notes;
    _selectedType = item.type;
    _selectedPriority = item.priority == TodoPriority.none
        ? TodoPriority.normal
        : item.priority;
    _selectedCategoryId = item.categoryId;
    _selectedDate = item.dueDate == null
        ? null
        : DateTime(item.dueDate!.year, item.dueDate!.month, item.dueDate!.day);
    _selectedTime = item.hasTime && item.dueDate != null
        ? TimeOfDay(hour: item.dueDate!.hour, minute: item.dueDate!.minute)
        : null;
  }

  String _formatSelectedTime(BuildContext context) {
    final base = _selectedDate ?? DateTime.now();
    final value = DateTime(
      base.year,
      base.month,
      base.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    return TodoDateFormatter.time(context, value);
  }

  Future<void> _pickDate() async {
    final l10n = context.l10n;
    var draft = _selectedDate ?? DateTime.now();

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) {
        return _PickerSheet(
          title: l10n.todoDate,
          cancelLabel: l10n.todoCancel,
          confirmLabel: l10n.todoSave,
          onCancel: () => Navigator.of(sheetContext).pop(),
          onConfirm: () {
            setState(() {
              _selectedDate = DateTime(draft.year, draft.month, draft.day);
            });
            Navigator.of(sheetContext).pop();
          },
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: draft,
            onDateTimeChanged: (value) => draft = value,
          ),
        );
      },
    );
  }

  Future<void> _pickTime() async {
    final l10n = context.l10n;
    final initial = _selectedTime ?? TimeOfDay.now();
    var draft = DateTime(2024, 1, 1, initial.hour, initial.minute);

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) {
        return _PickerSheet(
          title: l10n.todoTime,
          cancelLabel: l10n.todoCancel,
          confirmLabel: l10n.todoSave,
          onCancel: () => Navigator.of(sheetContext).pop(),
          onConfirm: () {
            setState(() {
              _selectedTime = TimeOfDay(hour: draft.hour, minute: draft.minute);
              _selectedDate ??= DateTime.now();
            });
            Navigator.of(sheetContext).pop();
          },
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.time,
            initialDateTime: draft,
            use24hFormat: _isSpanish(context),
            onDateTimeChanged: (value) => draft = value,
          ),
        );
      },
    );
  }

  void _showReminderSoon() {
    final message = _isSpanish(context)
        ? 'Los recordatorios de tareas llegarán pronto.'
        : 'Task reminders are coming soon.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _save() {
    if (!_canSave) return;

    final now = DateTime.now();
    final dueDate = _selectedDate == null
        ? null
        : DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            _selectedTime?.hour ?? 0,
            _selectedTime?.minute ?? 0,
          );

    final initial = widget.initialItem;
    final item = (initial ??
            TodoItem(
              id: 'todo-${DateTime.now().microsecondsSinceEpoch}',
              title: '',
              description: '',
              notes: '',
              createdAt: now,
              categoryId: _selectedCategoryId,
              priority: TodoPriority.normal,
              type: TodoType.free,
              isCompleted: false,
              xpReward: 10,
            ))
        .copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      notes: _notesController.text.trim(),
      dueDate: dueDate,
      hasTime: _selectedTime != null,
      categoryId: _selectedCategoryId,
      priority: _selectedPriority,
      type: _selectedType,
      linkedHabitId: _selectedType == TodoType.linkedHabit
          ? (initial?.linkedHabitId ?? 'linked-habit-placeholder')
          : null,
      xpReward: initial?.xpReward ?? 10,
    );

    Navigator.of(context).pop(item);
  }
}

class _CreateTodoInfoRow extends StatelessWidget {
  const _CreateTodoInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            _RowIconBox(icon: icon),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: TodoStyleResolver.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: _CreateTodoScreenState._mutedText,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              CupertinoIcons.chevron_forward,
              size: 14,
              color: _CreateTodoScreenState._mutedText,
            ),
          ],
        ),
      ),
    );
  }
}

class _RowIconBox extends StatelessWidget {
  const _RowIconBox({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: TodoStyleResolver.accentSoft.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 15,
        color: TodoStyleResolver.accentSoft.withValues(alpha: 0.86),
      ),
    );
  }
}

class _PriorityDot extends StatelessWidget {
  const _PriorityDot({
    required this.priority,
    required this.selected,
    required this.onTap,
  });

  final TodoPriority priority;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (priority) {
      TodoPriority.normal => const Color(0xFF7A9E7E),
      TodoPriority.high => const Color(0xFFC9A84C),
      TodoPriority.urgent => const Color(0xFFB8895A),
      TodoPriority.none => const Color(0xFFC9A84C),
    };

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: selected ? 24 : 20,
        height: selected ? 24 : 20,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.30),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5),
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  const _PickerSheet({
    required this.title,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
    required this.child,
  });

  final String title;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onCancel,
                child: Text(cancelLabel),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: TodoStyleResolver.textPrimary,
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onConfirm,
                child: Text(confirmLabel),
              ),
            ],
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
