import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../utils/app_theme.dart';
import '../utils/data_store.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _displayDate = DateTime.now();
  List<Map<String, dynamic>> _events = [];
  int? _selectedDay;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => _events = DataStore.getList('events'));

  List<Map<String, dynamic>> _eventsForDay(int day) {
    final dateStr = _dayStr(day);
    return _events.where((e) => e['date'] == dateStr).toList();
  }

  String _dayStr(int day) {
    return '${_displayDate.year}-${_displayDate.month.toString().padLeft(2,'0')}-${day.toString().padLeft(2,'0')}';
  }

  List<Map<String, dynamic>> get _upcomingEvents {
    final now = DateTime.now();
    return _events
      .where((e) => DateTime.tryParse(e['date'] as String? ?? '') != null &&
        (DateTime.tryParse(e['date'] as String? ?? '')!.isAfter(now) ||
         (e['date'] as String?) == DataStore.todayStr()))
      .toList()
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
  }

  void _addEvent([int? day]) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String date = day != null ? _dayStr(day) : DataStore.todayStr();
    String time = '';
    Color color = AppTheme.accent;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('📅 Add Event',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, color: AppTheme.textMuted), onPressed: () => Navigator.pop(ctx)),
              ]),
              const SizedBox(height: 12),
              TextField(controller: titleCtrl, style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Event Title *', hintText: 'Meeting, Birthday...')),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.tryParse(date) ?? DateTime.now(),
                        firstDate: DateTime(2020), lastDate: DateTime(2030),
                        builder: (c, child) => Theme(
                          data: Theme.of(c).copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.accent)),
                          child: child!),
                      );
                      if (picked != null) setS(() => date = DateFormat('yyyy-MM-dd').format(picked));
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date *'),
                      child: Text(date, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(context: ctx, initialTime: TimeOfDay.now(),
                        builder: (c, child) => Theme(
                          data: Theme.of(c).copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.accent)),
                          child: child!));
                      if (picked != null) setS(() => time = picked.format(ctx));
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Time'),
                      child: Text(time.isEmpty ? 'Pick time' : time,
                        style: TextStyle(color: time.isEmpty ? AppTheme.textMuted : AppTheme.textPrimary, fontSize: 13)),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              TextField(controller: descCtrl, style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Description', hintText: 'Event details...'),
                maxLines: 2),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) return;
                    _events.add({'id': DataStore.genId(), 'title': title, 'date': date,
                      'time': time, 'desc': descCtrl.text.trim(), 'color': '#6C63FF'});
                    DataStore.setList('events', _events);
                    setState(() {});
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Event'),
                )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(_displayDate.year, _displayDate.month, 1);
    final daysInMonth = DateTime(_displayDate.year, _displayDate.month + 1, 0).getDate();
    final startWeekday = firstDayOfMonth.weekday % 7; // 0=Sun

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('📅 Calendar')),
      body: Column(
        children: [
          // Month nav
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.textPrimary),
                  onPressed: () => setState(() => _displayDate = DateTime(_displayDate.year, _displayDate.month - 1)),
                ),
                Text(DateFormat('MMMM yyyy').format(_displayDate),
                  style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.textPrimary),
                  onPressed: () => setState(() => _displayDate = DateTime(_displayDate.year, _displayDate.month + 1)),
                ),
              ],
            ),
          ),

          // Day headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map((d) => Expanded(child: Center(
                  child: Text(d, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)))))
                .toList(),
            ),
          ),
          const SizedBox(height: 6),

          // Calendar grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, mainAxisSpacing: 2, crossAxisSpacing: 2, childAspectRatio: 1),
              itemCount: startWeekday + daysInMonth,
              itemBuilder: (_, index) {
                if (index < startWeekday) return const SizedBox.shrink();
                final day = index - startWeekday + 1;
                final isToday = DateTime.now().day == day &&
                  DateTime.now().month == _displayDate.month &&
                  DateTime.now().year == _displayDate.year;
                final dayEvents = _eventsForDay(day);
                final isSelected = _selectedDay == day;

                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = _selectedDay == day ? null : day),
                  onDoubleTap: () => _addEvent(day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.accentLight : isToday ? AppTheme.accentLight.withOpacity(0.5) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday ? Border.all(color: AppTheme.borderAccent) : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$day', style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: isToday || isSelected ? AppTheme.accent2 : AppTheme.textSecondary)),
                        if (dayEvents.isNotEmpty)
                          Wrap(children: dayEvents.take(2).map((e) => Container(
                            width: 5, height: 5, margin: const EdgeInsets.only(top: 1, right: 1),
                            decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                          )).toList()),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(color: AppTheme.border, height: 20),

          // Upcoming events
          Expanded(
            child: _upcomingEvents.isEmpty
              ? const Center(child: Text('No upcoming events', style: TextStyle(color: AppTheme.textMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: _upcomingEvents.length,
                  itemBuilder: (_, i) {
                    final e = _upcomingEvents[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: AppTheme.cardDecoration(),
                      child: ListTile(
                        leading: Container(width: 4, height: 48,
                          decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(2))),
                        title: Text(e['title'] as String? ?? '',
                          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                        subtitle: Text('${e['date']}${(e['time'] as String? ?? '').isNotEmpty ? ' · ${e['time']}' : ''}',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.textMuted),
                          onPressed: () {
                            _events.removeWhere((x) => x['id'] == e['id']);
                            DataStore.setList('events', _events);
                            setState(() {});
                          }),
                      ),
                    );
                  }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addEvent(),
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Event'),
      ),
    );
  }
}

extension _DaysInMonth on DateTime {
  int getDate() => DateTime(year, month + 1, 0).day;
}
