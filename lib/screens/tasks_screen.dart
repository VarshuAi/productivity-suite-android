import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../utils/app_theme.dart';
import '../utils/data_store.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Map<String, dynamic>> _tasks = [];
  String _filter = 'all';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _tasks = DataStore.getList('tasks'));
  }

  List<Map<String, dynamic>> get _filtered {
    var list = List<Map<String, dynamic>>.from(_tasks);
    if (_filter == 'pending') list = list.where((t) => t['done'] != true).toList();
    else if (_filter == 'done') list = list.where((t) => t['done'] == true).toList();
    else if (_filter == 'high') list = list.where((t) => t['priority'] == 'high' || t['priority'] == 'urgent').toList();
    final q = _searchCtrl.text.toLowerCase();
    if (q.isNotEmpty) list = list.where((t) => (t['title'] as String? ?? '').toLowerCase().contains(q)).toList();
    list.sort((a, b) {
      const o = {'urgent': 0, 'high': 1, 'medium': 2, 'low': 3};
      return (o[a['priority']] ?? 2).compareTo(o[b['priority']] ?? 2);
    });
    return list;
  }

  void _toggleTask(String id) {
    final idx = _tasks.indexWhere((t) => t['id'] == id);
    if (idx == -1) return;
    _tasks[idx]['done'] = !(_tasks[idx]['done'] as bool? ?? false);
    DataStore.setList('tasks', _tasks);
    setState(() {});
  }

  void _deleteTask(String id) {
    _tasks.removeWhere((t) => t['id'] == id);
    DataStore.setList('tasks', _tasks);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task deleted'), backgroundColor: AppTheme.bgCard));
  }

  void _openTaskModal({Map<String, dynamic>? task}) {
    final titleCtrl = TextEditingController(text: task?['title'] ?? '');
    final descCtrl = TextEditingController(text: task?['desc'] ?? '');
    final catCtrl = TextEditingController(text: task?['category'] ?? '');
    String priority = task?['priority'] ?? 'medium';
    String? dueDate = task?['due'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(task == null ? '✅ New Task' : '✏️ Edit Task',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, color: AppTheme.textMuted), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: titleCtrl, style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Task Title *', hintText: 'What needs to be done?')),
              const SizedBox(height: 10),
              TextField(controller: descCtrl, style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Description', hintText: 'Add details...'),
                maxLines: 3),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: priority,
                      dropdownColor: AppTheme.bgCard,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: ['low', 'medium', 'high', 'urgent'].map((p) =>
                        DropdownMenuItem(value: p, child: Text(p, style: TextStyle(color: AppTheme.priorityColor(p))))).toList(),
                      onChanged: (v) => setModalState(() => priority = v!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: dueDate != null ? DateTime.parse(dueDate!) : DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (ctx, child) => Theme(
                            data: Theme.of(ctx).copyWith(
                              colorScheme: const ColorScheme.dark(primary: AppTheme.accent)),
                            child: child!),
                        );
                        if (picked != null) setModalState(() => dueDate = DateFormat('yyyy-MM-dd').format(picked));
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Due Date'),
                        child: Text(dueDate ?? 'Pick date',
                          style: TextStyle(color: dueDate != null ? AppTheme.textPrimary : AppTheme.textMuted, fontSize: 13)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(controller: catCtrl, style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Category', hintText: 'Work, Health...')),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) return;
                    if (task == null) {
                      _tasks.insert(0, {
                        'id': DataStore.genId(), 'title': title, 'desc': descCtrl.text.trim(),
                        'priority': priority, 'due': dueDate, 'category': catCtrl.text.trim(),
                        'done': false, 'createdAt': DateTime.now().toIso8601String(),
                      });
                    } else {
                      final idx = _tasks.indexWhere((t) => t['id'] == task['id']);
                      if (idx != -1) {
                        _tasks[idx] = {...task, 'title': title, 'desc': descCtrl.text.trim(),
                          'priority': priority, 'due': dueDate, 'category': catCtrl.text.trim()};
                      }
                    }
                    DataStore.setList('tasks', _tasks);
                    setState(() {});
                    Navigator.pop(ctx);
                  },
                  child: Text(task == null ? 'Create Task' : 'Update Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('✅ Task Manager'),
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded), onPressed: () => _openTaskModal(),
            tooltip: 'New Task'),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textMuted),
                hintText: 'Search tasks...'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f in [('all', 'All'), ('pending', 'Pending'), ('done', 'Done'), ('high', 'High Priority')])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _FilterChip(
                        label: f.$2,
                        selected: _filter == f.$1,
                        onTap: () => setState(() => _filter = f.$1),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
              ? const Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('✅', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 12),
                    Text('No tasks here!', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                  ]))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final t = _filtered[i];
                    final done = t['done'] == true;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: AppTheme.cardDecoration(
                        borderColor: done ? AppTheme.border : null),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        leading: GestureDetector(
                          onTap: () => _toggleTask(t['id'] as String),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: done ? AppTheme.success : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(color: done ? AppTheme.success : AppTheme.borderAccent, width: 1.5),
                            ),
                            child: done ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
                          ),
                        ),
                        title: Text(t['title'] as String? ?? '',
                          style: TextStyle(
                            color: done ? AppTheme.textMuted : AppTheme.textPrimary,
                            decoration: done ? TextDecoration.lineThrough : null,
                            fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((t['desc'] as String? ?? '').isNotEmpty)
                              Padding(padding: const EdgeInsets.only(top: 2),
                                child: Text(t['desc'] as String, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted))),
                            const SizedBox(height: 6),
                            Row(children: [
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
                              if ((t['due'] as String? ?? '').isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Text('📅 ${t['due']}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              ],
                            ]),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textMuted),
                              onPressed: () => _openTaskModal(task: t)),
                            IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.textMuted),
                              onPressed: () => _deleteTask(t['id'] as String)),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTaskModal(),
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Task'),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accentLight : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.borderAccent : AppTheme.border),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500,
          color: selected ? AppTheme.accent2 : AppTheme.textSecondary)),
      ),
    );
  }
}
