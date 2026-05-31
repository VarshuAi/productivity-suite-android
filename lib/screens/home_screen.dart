import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_theme.dart';
import '../utils/data_store.dart';
import 'tasks_screen.dart';
import 'notes_screen.dart';
import 'habits_screen.dart';
import 'pomodoro_screen.dart';
import 'budget_screen.dart';
import 'calendar_screen.dart';
import 'passwords_screen.dart';
import 'clipboard_screen.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fabAnimController;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Home', emoji: '🏠'),
    _NavItem(icon: Icons.check_circle_outline_rounded, label: 'Tasks', emoji: '✅'),
    _NavItem(icon: Icons.sticky_note_2_outlined, label: 'Notes', emoji: '📝'),
    _NavItem(icon: Icons.local_fire_department_outlined, label: 'Habits', emoji: '🔥'),
    _NavItem(icon: Icons.more_horiz_rounded, label: 'More', emoji: '⚡'),
  ];

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0: return const DashboardScreen();
      case 1: return const TasksScreen();
      case 2: return const NotesScreen();
      case 3: return const HabitsScreen();
      case 4: return const MoreScreen();
      default: return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
                .animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: _buildPage(_selectedIndex),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          border: const Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 62,
            child: Row(
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final selected = _selectedIndex == i;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedIndex = i),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: selected ? AppTheme.accentLight : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              item.icon,
                              size: 22,
                              color: selected ? AppTheme.accent2 : AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              color: selected ? AppTheme.accent2 : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String emoji;
  const _NavItem({required this.icon, required this.label, required this.emoji});
}

// ─── MORE SCREEN ─────────────────────────────────────────────────────────────
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = [
      ('⏱️', 'Pomodoro', 'Focus timer & sessions', const PomodoroScreen()),
      ('💰', 'Budget', 'Income & expense tracker', const BudgetScreen()),
      ('📅', 'Calendar', 'Events & planner', const CalendarScreen()),
      ('🔐', 'Passwords', 'Secure local vault', const PasswordsScreen()),
      ('📋', 'Clipboard', 'Clipboard history', const ClipboardScreen()),
    ];

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: AppTheme.bgPrimary,
              title: const Text('More Modules'),
              automaticallyImplyLeading: false,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final m = modules[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: AppTheme.cardDecoration(),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.accentLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(m.$1, style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                        title: Text(m.$2, style: const TextStyle(
                          color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                        subtitle: Text(m.$3, style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                        onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => m.$4)),
                      ),
                    );
                  },
                  childCount: modules.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
