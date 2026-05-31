import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../utils/data_store.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class Habit {
  final String id;
  String name;
  String icon;   // emoji
  String color;  // hex e.g. "0xFF6C63FF"
  int goal;      // times per day
  Map<String, int> checks; // date string (yyyy-MM-dd) -> count
  final String createdAt;

  Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.goal,
    required this.checks,
    required this.createdAt,
  });

  factory Habit.fromMap(Map<String, dynamic> m) => Habit(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        icon: m['icon'] as String? ?? '✅',
        color: m['color'] as String? ?? '0xFF6C63FF',
        goal: (m['goal'] as num?)?.toInt() ?? 1,
        checks: Map<String, int>.from(
          (m['checks'] as Map?)?.map(
                (k, v) => MapEntry(k.toString(), (v as num).toInt()),
              ) ??
              {},
        ),
        createdAt: m['createdAt'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
        'goal': goal,
        'checks': checks,
        'createdAt': createdAt,
      };

  int todayCount() => checks[DataStore.todayStr()] ?? 0;

  bool completedToday() => todayCount() >= goal;

  Color get colorValue => Color(int.tryParse(color) ?? 0xFF6C63FF);
}

// ─────────────────────────────────────────────────────────────────────────────
// Streak calculation
// ─────────────────────────────────────────────────────────────────────────────

int calcStreak(Habit habit) {
  int streak = 0;
  DateTime day = DateTime.now();
  final fmt = DateFormat('yyyy-MM-dd');

  // If today is incomplete, start checking from yesterday
  final todayKey = fmt.format(day);
  final todayCount = habit.checks[todayKey] ?? 0;
  if (todayCount < habit.goal) {
    day = day.subtract(const Duration(days: 1));
  }

  // Walk backwards
  for (int i = 0; i < 365; i++) {
    final key = fmt.format(day);
    final count = habit.checks[key] ?? 0;
    if (count >= habit.goal) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }
  return streak;
}

// ─────────────────────────────────────────────────────────────────────────────
// HabitsScreen
// ─────────────────────────────────────────────────────────────────────────────

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  List<Habit> _habits = [];

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  // ── persistence ────────────────────────────────────────────────────────────

  void _loadHabits() {
    final raw = DataStore.getList('habits');
    setState(() {
      _habits = raw
          .map((e) => Habit.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    });
  }

  void _saveHabits() {
    DataStore.setList('habits', _habits.map((h) => h.toMap()).toList());
  }

  // ── actions ────────────────────────────────────────────────────────────────

  void _checkHabit(Habit habit) {
    setState(() {
      final key = DataStore.todayStr();
      final cur = habit.checks[key] ?? 0;
      if (cur < habit.goal) {
        habit.checks[key] = cur + 1;
      } else {
        habit.checks[key] = 0; // toggle off
      }
    });
    _saveHabits();
  }

  void _deleteHabit(Habit habit) {
    setState(() => _habits.removeWhere((h) => h.id == habit.id));
    _saveHabits();
  }

  void _addHabit(Habit habit) {
    setState(() => _habits.add(habit));
    _saveHabits();
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final completed = _habits.where((h) => h.completedToday()).length;

    return Scaffold(
      backgroundColor: const Color(AppTheme.bgPrimary),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(completed)),
          if (_habits.isEmpty)
            SliverFillRemaining(child: _buildEmpty())
          else ...[
            SliverToBoxAdapter(child: _buildSummaryBar(completed)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildHabitCard(_habits[i]),
                  childCount: _habits.length,
                ),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  mainAxisExtent: 200,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildHeatmapSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddModal,
        backgroundColor: const Color(AppTheme.accent),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(int completed) {
    final today = DateFormat('EEEE, MMM d').format(DateTime.now());
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 52, 16, 16),
      decoration: const BoxDecoration(
        color: Color(AppTheme.bgSecondary),
        border: Border(bottom: BorderSide(color: Color(AppTheme.border))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Habits',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(AppTheme.textPrimary),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                today,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(AppTheme.textMuted),
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_habits.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: completed == _habits.length
                    ? const Color(AppTheme.success).withOpacity(0.15)
                    : const Color(AppTheme.accentLight),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: completed == _habits.length
                      ? const Color(AppTheme.success).withOpacity(0.4)
                      : const Color(AppTheme.borderAccent),
                ),
              ),
              child: Text(
                '$completed / ${_habits.length}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: completed == _habits.length
                      ? const Color(AppTheme.success)
                      : const Color(AppTheme.accent2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(int completed) {
    if (_habits.isEmpty) return const SizedBox.shrink();
    final pct = _habits.isEmpty ? 0.0 : completed / _habits.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Today's progress",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(AppTheme.textSecondary),
                ),
              ),
              const Spacer(),
              Text(
                '${(pct * 100).round()}%',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(AppTheme.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: const Color(AppTheme.bgCard),
              valueColor: AlwaysStoppedAnimation<Color>(
                pct >= 1.0
                    ? const Color(AppTheme.success)
                    : const Color(AppTheme.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(Habit habit) {
    final streak = calcStreak(habit);
    final todayCount = habit.todayCount();
    final completed = habit.completedToday();
    final pct = (todayCount / habit.goal).clamp(0.0, 1.0);
    final color = habit.colorValue;

    return GestureDetector(
      onLongPress: () => _showDeleteConfirm(habit),
      child: Container(
        decoration: AppTheme.cardDecoration().copyWith(
          border: Border.all(
            color: completed
                ? color.withOpacity(0.5)
                : const Color(AppTheme.border),
          ),
        ),
        child: Stack(
          children: [
            // glow accent when completed
            if (completed)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: RadialGradient(
                      center: Alignment.topRight,
                      radius: 1.2,
                      colors: [color.withOpacity(0.12), Colors.transparent],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // icon + streak
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(habit.icon, style: const TextStyle(fontSize: 22)),
                      ),
                      const Spacer(),
                      if (streak > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(AppTheme.warning).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 10)),
                              const SizedBox(width: 3),
                              Text(
                                '$streak',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(AppTheme.warning),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // name
                  Text(
                    habit.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(AppTheme.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$todayCount / ${habit.goal}x today',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(AppTheme.textMuted),
                    ),
                  ),
                  const Spacer(),
                  // progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 4,
                      backgroundColor: const Color(AppTheme.border),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // check button
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () => _checkHabit(habit),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: completed ? color : color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              completed ? Icons.check : Icons.add,
                              size: 14,
                              color: completed
                                  ? Colors.white
                                  : color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              completed ? 'Done!' : 'Check in',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: completed ? Colors.white : color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapSection() {
    if (_habits.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '7-Day Overview',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(AppTheme.textPrimary),
            ),
          ),
          const SizedBox(height: 12),
          ..._habits.map((h) => _buildHabitHeatmapRow(h)),
        ],
      ),
    );
  }

  Widget _buildHabitHeatmapRow(Habit habit) {
    final days = List.generate(7, (i) {
      return DateTime.now().subtract(Duration(days: 6 - i));
    });
    final fmt = DateFormat('yyyy-MM-dd');
    final dayFmt = DateFormat('E');
    final color = habit.colorValue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(habit.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  habit.name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(AppTheme.textPrimary),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(AppTheme.warning).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '🔥 ${calcStreak(habit)} day streak',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(AppTheme.warning),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((day) {
              final key = fmt.format(day);
              final count = habit.checks[key] ?? 0;
              final frac = (count / habit.goal).clamp(0.0, 1.0);
              final isToday = key == DataStore.todayStr();

              return Expanded(
                child: Column(
                  children: [
                    Text(
                      dayFmt.format(day),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: isToday
                            ? color
                            : const Color(AppTheme.textMuted),
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 32,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: frac == 0
                            ? const Color(AppTheme.bgPrimary)
                            : color.withOpacity(0.2 + 0.8 * frac),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isToday
                              ? color.withOpacity(0.6)
                              : const Color(AppTheme.border),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: count > 0
                          ? Text(
                              '$count',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: frac >= 1.0
                                    ? Colors.white
                                    : color,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎯', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'No habits yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(AppTheme.textPrimary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Build streaks and track your daily goals',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(AppTheme.textMuted),
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _showAddModal,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add First Habit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppTheme.accent),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ── modals ─────────────────────────────────────────────────────────────────

  void _showAddModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddHabitSheet(onAdd: _addHabit),
    );
  }

  void _showDeleteConfirm(Habit habit) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(AppTheme.bgCard),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete "${habit.name}"?',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(AppTheme.textPrimary),
          ),
        ),
        content: Text(
          'All check-in history will be lost.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(AppTheme.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    color: const Color(AppTheme.textSecondary))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteHabit(habit);
            },
            child: Text('Delete',
                style: GoogleFonts.inter(color: const Color(AppTheme.danger))),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Habit Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddHabitSheet extends StatefulWidget {
  final ValueChanged<Habit> onAdd;
  const _AddHabitSheet({required this.onAdd});

  @override
  State<_AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<_AddHabitSheet> {
  final _nameCtrl = TextEditingController();
  String _icon = '✅';
  String _color = '0xFF6C63FF';
  int _goal = 1;

  // Palette of preset colors
  static const _colorOptions = [
    ('Purple', '0xFF6C63FF'),
    ('Violet', '0xFFA78BFA'),
    ('Blue', '0xFF3B82F6'),
    ('Teal', '0xFF14B8A6'),
    ('Green', '0xFF22C55E'),
    ('Yellow', '0xFFF59E0B'),
    ('Orange', '0xFFF97316'),
    ('Red', '0xFFEF4444'),
    ('Pink', '0xFFEC4899'),
  ];

  // Common emojis for quick pick
  static const _emojiOptions = [
    '✅', '💪', '🏃', '📚', '💧', '🧘', '🥗', '🛌',
    '💊', '🎯', '✍️', '🎸', '🧹', '🌿', '🐾', '☀️',
    '🚴', '🏋️', '🤸', '🧠', '💻', '🎨', '🎵', '🍎',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final habit = Habit(
      id: DataStore.genId(),
      name: name,
      icon: _icon,
      color: _color,
      goal: _goal,
      checks: {},
      createdAt: DateTime.now().toIso8601String(),
    );
    widget.onAdd(habit);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: const Color(AppTheme.bgCard),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(AppTheme.border)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(AppTheme.textMuted),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'New Habit',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(AppTheme.textPrimary),
              ),
            ),
            const SizedBox(height: 20),

            // Name
            _label('Name'),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: const Color(AppTheme.textPrimary),
              ),
              decoration: _inputDecoration('e.g. Morning Run'),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),

            // Icon picker
            _label('Icon'),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _emojiOptions.map((e) {
                  final sel = e == _icon;
                  return GestureDetector(
                    onTap: () => setState(() => _icon = e),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(AppTheme.accentLight)
                            : const Color(AppTheme.bgSecondary),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel
                              ? const Color(AppTheme.borderAccent)
                              : const Color(AppTheme.border),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(e, style: const TextStyle(fontSize: 20)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Color picker
            _label('Color'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colorOptions.map((pair) {
                final (label, hex) = pair;
                final col = Color(int.parse(hex));
                final sel = hex == _color;
                return GestureDetector(
                  onTap: () => setState(() => _color = hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: col,
                      shape: BoxShape.circle,
                      border: sel
                          ? Border.all(color: Colors.white, width: 2.5)
                          : null,
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                color: col.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: sel
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Goal
            _label('Daily goal (times/day)'),
            const SizedBox(height: 8),
            Row(
              children: [
                _goalButton(Icons.remove, () {
                  if (_goal > 1) setState(() => _goal--);
                }),
                const SizedBox(width: 16),
                SizedBox(
                  width: 48,
                  child: Text(
                    '$_goal',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(AppTheme.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                _goalButton(Icons.add, () => setState(() => _goal++)),
                const Spacer(),
                Text(
                  'time${_goal > 1 ? 's' : ''} per day',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(AppTheme.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nameCtrl.text.trim().isEmpty ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppTheme.accent),
                  disabledBackgroundColor:
                      const Color(AppTheme.accent).withOpacity(0.4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Add Habit',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(AppTheme.textSecondary),
          letterSpacing: 0.5,
        ),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          color: const Color(AppTheme.textMuted),
        ),
        filled: true,
        fillColor: const Color(AppTheme.bgSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(AppTheme.border)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(AppTheme.border)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(AppTheme.borderAccent)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  Widget _goalButton(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(AppTheme.bgSecondary),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(AppTheme.border)),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: const Color(AppTheme.textSecondary)),
        ),
      );
}
