import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_theme.dart';
import '../utils/data_store.dart';

class PasswordsScreen extends StatefulWidget {
  const PasswordsScreen({super.key});

  @override
  State<PasswordsScreen> createState() => _PasswordsScreenState();
}

class _PasswordsScreenState extends State<PasswordsScreen> {
  bool _unlocked = false;
  final _masterCtrl = TextEditingController();
  List<Map<String, dynamic>> _passwords = [];
  final _searchCtrl = TextEditingController();
  static const _masterPass = 'admin123';

  void _unlock() {
    if (_masterCtrl.text == _masterPass) {
      setState(() {
        _unlocked = true;
        _passwords = DataStore.getList('passwords');
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Wrong master password'), backgroundColor: AppTheme.danger));
      _masterCtrl.clear();
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return _passwords;
    return _passwords.where((p) =>
      (p['site'] as String? ?? '').toLowerCase().contains(q) ||
      (p['username'] as String? ?? '').toLowerCase().contains(q)).toList();
  }

  void _openModal({Map<String, dynamic>? pass}) {
    final siteCtrl = TextEditingController(text: pass?['site'] ?? '');
    final userCtrl = TextEditingController(text: pass?['username'] ?? '');
    final passCtrl = TextEditingController(text: pass?['password'] ?? '');
    final urlCtrl = TextEditingController(text: pass?['url'] ?? '');
    bool showPass = false;

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
                Text(pass == null ? '🔐 Add Password' : '✏️ Edit Password',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, color: AppTheme.textMuted), onPressed: () => Navigator.pop(ctx)),
              ]),
              const SizedBox(height: 12),
              TextField(controller: siteCtrl, style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Site / App Name *', hintText: 'Google, Netflix...')),
              const SizedBox(height: 10),
              TextField(controller: userCtrl, style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Username / Email', hintText: 'your@email.com')),
              const SizedBox(height: 10),
              TextField(
                controller: passCtrl,
                obscureText: !showPass,
                style: GoogleFonts.jetBrainsMono(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Password *',
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: Icon(showPass ? Icons.visibility_off : Icons.visibility, size: 18, color: AppTheme.textMuted),
                        onPressed: () => setS(() => showPass = !showPass)),
                      IconButton(icon: const Icon(Icons.casino_outlined, size: 18, color: AppTheme.textMuted),
                        tooltip: 'Generate',
                        onPressed: () {
                          const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_+-=';
                          final pw = List.generate(16, (_) => chars[(DateTime.now().microsecond * 9973 + _.hashCode) % chars.length]).join();
                          setS(() => passCtrl.text = pw);
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(controller: urlCtrl, style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'URL', hintText: 'https://...')),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (siteCtrl.text.isEmpty || passCtrl.text.isEmpty) return;
                    final entry = {
                      'id': pass?['id'] ?? DataStore.genId(),
                      'site': siteCtrl.text.trim(), 'username': userCtrl.text.trim(),
                      'password': passCtrl.text, 'url': urlCtrl.text.trim(),
                      'updatedAt': DateTime.now().toIso8601String(),
                    };
                    if (pass == null) {
                      _passwords.insert(0, entry);
                    } else {
                      final idx = _passwords.indexWhere((p) => p['id'] == pass['id']);
                      if (idx != -1) _passwords[idx] = entry;
                    }
                    DataStore.setList('passwords', _passwords);
                    setState(() {});
                    Navigator.pop(ctx);
                  },
                  child: Text(pass == null ? 'Save Password' : 'Update'),
                )),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied!'), backgroundColor: AppTheme.bgCard));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('🔐 Passwords'),
        actions: _unlocked ? [
          IconButton(icon: const Icon(Icons.lock_outline_rounded), onPressed: () => setState(() => _unlocked = false)),
          IconButton(icon: const Icon(Icons.add_rounded), onPressed: () => _openModal()),
        ] : [],
      ),
      body: !_unlocked
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔒', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text('Vault Locked', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  const Text('Enter master password to access', style: TextStyle(color: AppTheme.textMuted)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _masterCtrl,
                    obscureText: true,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(labelText: 'Master Password',
                      prefixIcon: Icon(Icons.key_rounded, color: AppTheme.textMuted)),
                    onSubmitted: (_) => _unlock(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity,
                    child: ElevatedButton(onPressed: _unlock, child: const Text('Unlock Vault'))),
                  const SizedBox(height: 12),
                  Text('Default: admin123', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ),
          )
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textMuted),
                    hintText: 'Search passwords...'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Expanded(
                child: _filtered.isEmpty
                  ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('🔐', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('No passwords saved yet', style: TextStyle(color: AppTheme.textMuted)),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final p = _filtered[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: AppTheme.cardDecoration(),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  const Text('🌐', style: TextStyle(fontSize: 20)),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(p['site'] as String? ?? '',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary))),
                                  IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textMuted),
                                    onPressed: () => _openModal(pass: p)),
                                  IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.textMuted),
                                    onPressed: () {
                                      _passwords.removeWhere((x) => x['id'] == p['id']);
                                      DataStore.setList('passwords', _passwords);
                                      setState(() {});
                                    }),
                                ]),
                                if ((p['username'] as String? ?? '').isNotEmpty)
                                  Text('👤 ${p['username']}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                Text('🔑 ••••••••••••',
                                  style: GoogleFonts.jetBrainsMono(fontSize: 13, color: AppTheme.textMuted, letterSpacing: 2)),
                                const SizedBox(height: 10),
                                Row(children: [
                                  Expanded(child: OutlinedButton.icon(
                                    onPressed: () => _copyToClipboard(p['password'] as String? ?? '', 'Password'),
                                    icon: const Icon(Icons.copy_rounded, size: 14),
                                    label: const Text('Copy Pass', style: TextStyle(fontSize: 12)),
                                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.accent2,
                                      side: const BorderSide(color: AppTheme.borderAccent),
                                      padding: const EdgeInsets.symmetric(vertical: 6)),
                                  )),
                                  const SizedBox(width: 8),
                                  if ((p['username'] as String? ?? '').isNotEmpty)
                                    Expanded(child: OutlinedButton.icon(
                                      onPressed: () => _copyToClipboard(p['username'] as String? ?? '', 'Username'),
                                      icon: const Icon(Icons.person_outline_rounded, size: 14),
                                      label: const Text('Copy User', style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(foregroundColor: AppTheme.textSecondary,
                                        side: const BorderSide(color: AppTheme.border),
                                        padding: const EdgeInsets.symmetric(vertical: 6)),
                                    )),
                                ]),
                              ],
                            ),
                          ),
                        );
                      }),
              ),
            ],
          ),
      floatingActionButton: _unlocked ? FloatingActionButton.extended(
        onPressed: () => _openModal(),
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Password'),
      ) : null,
    );
  }
}
