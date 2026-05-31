import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../utils/app_theme.dart';
import '../utils/data_store.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<String> _quotes = [
    "The secret of getting ahead is getting started. — Mark Twain",
    "It always seems impossible until it's done. — Nelson Mandela",
    "Don't watch the clock; do what it does. Keep going. — Sam Levenson",
    "The future depends on what you do today. — Mahatma Gandhi",
    "Focus on being productive instead of busy. — Tim Ferriss",
    "Well done is better than well said. — Benjamin Franklin",
  ];

  int _pendingTasks = 0;
  int _totalHabits = 0;
  int _doneHabits = 0;
  double _balance = 0;
  int _notes = 0;
  int _sessions = 0;
  late String _quote;

  @override
  void initState() {
    super.initState();
    _quote = _quotes[DateTime.now().day % _quotes.length];
    _loadStats();
  }

  void _loadStats() {
    final tasks = DataStore.getList('tasks');
    _pendingTasks = tasks.where((t) => t['done'] != true).length;

    final habits = DataStore.getList('habits');
    _totalHabits = habits.length;
    final today = DataStore.todayStr();
    _doneHabits = habits.where((h) {
      final checks = h['checks'] as Map? ?? {};
      return (checks[today] as int? ?? 0) >= (h['goal'] as int? ?? 1);
    }).length;

    final txs = DataStore.getList('transactions');
    final income = txs.where((t) => t['type'] == 'income').fold(0.0, (s, t) => s + (t['amount'] as num));
    final expense = txs.where((t) => t['type'] == 'expense').fold(0.0, (s, t) => s + (t['amount'] as num));
    _balance = income - expense;

    final notes = DataStore.getList('notes');
    _notes = notes.length;

    final log = DataStore.getList('pomodoro_log');
    _sessions = log.where((l) => l['date'] == today && l['type'] == 'work').length;

    setState(() {});
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadStats(),
          color: AppTheme.accent,
          backgroundColor: AppTheme.bgCard,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              gradient: AppTheme.accentGradient,
                              shape: BoxShape.circle,
                              boxShadow: AppTheme.glowShadow,
                            ),
                            child: const Center(child: Text('V',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$_greeting! 👋',
                                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary)),
                                Text(DateFormat('EEEE, MMM d').format(DateTime.now()),
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textMuted),
                            onPressed: _loadStats,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Stats Grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildListDelegate([
                    _DashCard(emoji: '✅', label: 'Pending Tasks', value: '$_pendingTasks',
                      color: AppTheme.accent, onTap: () {}),
                    _DashCard(emoji: '🔥', label: 'Habits Today', value: '$_doneHabits/$_totalHabits',
                      color: AppTheme.warning, onTap: () {}),
                    _DashCard(emoji: '💰', label: 'Balance', value: '₹${_balance.toStringAsFixed(0)}',
                      color: _balance >= 0 ? AppTheme.success : AppTheme.danger, onTap: () {}),
                    _DashCard(emoji: '⏱️', label: 'Focus Sessions', value: '$_sessions',
                      color: AppTheme.danger, onTap: () {}),
                    _DashCard(emoji: '📝', label: 'Notes', value: '$_notes',
                      color: AppTheme.info, onTap: () {}),
                  ]),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.6,
                  ),
                ),
              ),

              // Quote Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: AppTheme.cardDecoration(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Text('💡', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 8),
                          Text('Daily Motivation', style: AppTheme.labelStyle),
                        ]),
                        const SizedBox(height: 12),
                        Text('"$_quote"',
                          style: GoogleFonts.inter(
                            fontSize: 14, color: AppTheme.textPrimary,
                            fontStyle: FontStyle.italic, height: 1.6)),
                      ],
                    ),
                  ),
                ),
              ),

              // Today's Tasks
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  child: Container(
                    decoration: AppTheme.cardDecoration(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Text('📋', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 8),
                          Text("Today's Tasks", style: AppTheme.labelStyle),
                        ]),
                        const SizedBox(height: 12),
                        _buildTasksList(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTasksList() {
    final tasks = DataStore.getList('tasks');
    final pending = tasks.where((t) => t['done'] != true).take(5).toList();

    if (pending.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text('🎉 All tasks done!', style: TextStyle(color: AppTheme.textMuted))),
      );
    }

    return Column(
      children: pending.map((t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: AppTheme.priorityColor(t['priority'] as String? ?? 'medium'),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(t['title'] as String? ?? '',
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              overflow: TextOverflow.ellipsis)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.priorityColor(t['priority'] as String? ?? 'medium').withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(t['priority'] as String? ?? 'medium',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                  color: AppTheme.priorityColor(t['priority'] as String? ?? 'medium'))),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

class _DashCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _DashCard({required this.emoji, required this.label, required this.value,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.w800, color: color)),
                Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
