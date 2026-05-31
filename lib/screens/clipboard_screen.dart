import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_theme.dart';
import '../utils/data_store.dart';

class ClipboardScreen extends StatefulWidget {
  const ClipboardScreen({super.key});

  @override
  State<ClipboardScreen> createState() => _ClipboardScreenState();
}

class _ClipboardScreenState extends State<ClipboardScreen> {
  List<Map<String, dynamic>> _history = [];
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => _history = DataStore.getList('clipboard_history'));

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return _history;
    return _history.where((c) => (c['text'] as String? ?? '').toLowerCase().contains(q)).toList();
  }

  Future<void> _captureClipboard() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clipboard is empty'), backgroundColor: AppTheme.bgCard));
      return;
    }
    if (_history.isNotEmpty && _history[0]['text'] == text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already captured'), backgroundColor: AppTheme.bgCard));
      return;
    }
    _history.insert(0, {
      'id': DataStore.genId(), 'text': text,
      'time': TimeOfDay.now().format(context),
      'date': DataStore.todayStr(),
      'capturedAt': DateTime.now().toIso8601String(),
    });
    if (_history.length > 200) _history = _history.take(200).toList();
    await DataStore.setList('clipboard_history', _history);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📋 Clipboard captured!'), backgroundColor: AppTheme.bgCard));
  }

  void _copyItem(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard!'), backgroundColor: AppTheme.bgCard));
  }

  void _deleteItem(String id) {
    _history.removeWhere((c) => c['id'] == id);
    DataStore.setList('clipboard_history', _history);
    setState(() {});
  }

  void _clearAll() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.bgCard,
      title: const Text('Clear History', style: TextStyle(color: AppTheme.textPrimary)),
      content: const Text('Delete all clipboard history?', style: TextStyle(color: AppTheme.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            DataStore.setList('clipboard_history', []);
            setState(() => _history = []);
            Navigator.pop(ctx);
          },
          child: const Text('Clear All', style: TextStyle(color: AppTheme.danger)),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('📋 Clipboard'),
        actions: [
          IconButton(icon: const Icon(Icons.delete_sweep_outlined), onPressed: _clearAll, tooltip: 'Clear all'),
          IconButton(icon: const Icon(Icons.add_to_photos_outlined), onPressed: _captureClipboard, tooltip: 'Capture'),
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
                hintText: 'Search clipboard history...'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                Text('${_history.length} items',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _captureClipboard,
                  icon: const Icon(Icons.content_paste_go_rounded, size: 14),
                  label: const Text('Capture Now', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.accent2),
                ),
              ],
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('📋', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('No clipboard history', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Tap "Capture Now" to save current clipboard', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final c = _filtered[i];
                    final text = c['text'] as String? ?? '';
                    final isUrl = text.startsWith('http');
                    final isCode = text.contains('\n') || text.length > 100;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: AppTheme.cardDecoration(),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Type indicator
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentLight,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isUrl ? '🔗 URL' : isCode ? '💻 Code' : '📝 Text',
                                  style: const TextStyle(fontSize: 10, color: AppTheme.accent2, fontWeight: FontWeight.w600)),
                              ),
                              const Spacer(),
                              Text('${c['time']} · ${c['date']}',
                                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                            ]),
                            const SizedBox(height: 8),
                            Text(text,
                              style: isCode
                                ? GoogleFonts.jetBrainsMono(fontSize: 12, color: AppTheme.textSecondary)
                                : const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 10),
                            Row(children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _copyItem(text),
                                  icon: const Icon(Icons.copy_rounded, size: 14),
                                  label: const Text('Copy', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.accent2,
                                    side: const BorderSide(color: AppTheme.borderAccent),
                                    padding: const EdgeInsets.symmetric(vertical: 6)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.textMuted),
                                onPressed: () => _deleteItem(c['id'] as String),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    );
                  }),
          ),
        ],
      ),
    );
  }
}
