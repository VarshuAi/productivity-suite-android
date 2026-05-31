import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../utils/data_store.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class Note {
  final String id;
  String title;
  String content;
  final String createdAt;
  String updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.fromMap(Map<String, dynamic> m) => Note(
        id: m['id'] as String,
        title: m['title'] as String? ?? '',
        content: m['content'] as String? ?? '',
        createdAt: m['createdAt'] as String? ?? '',
        updatedAt: m['updatedAt'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  Note copyWith({String? title, String? content, String? updatedAt}) => Note(
        id: id,
        title: title ?? this.title,
        content: content ?? this.content,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// NotesScreen
// ─────────────────────────────────────────────────────────────────────────────

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Note> _notes = [];
  List<Note> _filtered = [];
  Note? _selectedNote; // used on tablet/wide layout
  final _searchCtrl = TextEditingController();
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── persistence ────────────────────────────────────────────────────────────

  void _loadNotes() {
    final raw = DataStore.getList('notes');
    setState(() {
      _notes = raw.map((e) => Note.fromMap(Map<String, dynamic>.from(e))).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _filtered = List.from(_notes);
    });
  }

  void _saveNotes() {
    DataStore.setList('notes', _notes.map((n) => n.toMap()).toList());
  }

  // ── search ─────────────────────────────────────────────────────────────────

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_notes)
          : _notes
              .where((n) =>
                  n.title.toLowerCase().contains(q) ||
                  n.content.toLowerCase().contains(q))
              .toList();
    });
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────

  void _createNote() {
    final now = DateTime.now().toIso8601String();
    final note = Note(
      id: DataStore.genId(),
      title: '',
      content: '',
      createdAt: now,
      updatedAt: now,
    );
    setState(() {
      _notes.insert(0, note);
      _filtered = List.from(_notes);
    });
    _saveNotes();
    _openEditor(note);
  }

  void _deleteNote(Note note) {
    setState(() {
      _notes.removeWhere((n) => n.id == note.id);
      _filtered.removeWhere((n) => n.id == note.id);
      if (_selectedNote?.id == note.id) _selectedNote = null;
    });
    _saveNotes();
  }

  void _updateNote(Note updated) {
    final idx = _notes.indexWhere((n) => n.id == updated.id);
    if (idx == -1) return;
    setState(() {
      _notes[idx] = updated;
      _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _filtered = List.from(_notes);
      if (_selectedNote?.id == updated.id) _selectedNote = updated;
    });
    _saveNotes();
  }

  // ── navigation ─────────────────────────────────────────────────────────────

  void _openEditor(Note note) {
    final isWide = MediaQuery.of(context).size.width >= 720;
    if (isWide) {
      setState(() => _selectedNote = note);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NoteEditorPage(
            note: note,
            onSave: _updateNote,
            onDelete: _deleteNote,
          ),
        ),
      ).then((_) => _loadNotes());
    }
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  String _formatDate(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return DateFormat('h:mm a').format(dt);
      }
      return DateFormat('MMM d').format(dt);
    } catch (_) {
      return '';
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      backgroundColor: const Color(AppTheme.bgPrimary),
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        _buildHeader(showBack: false),
        _buildSearchBar(),
        Expanded(child: _buildNoteList(narrow: true)),
      ],
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        SizedBox(
          width: 300,
          child: Column(
            children: [
              _buildHeader(showBack: false),
              _buildSearchBar(),
              Expanded(child: _buildNoteList(narrow: false)),
            ],
          ),
        ),
        Container(width: 1, color: const Color(AppTheme.border)),
        Expanded(
          child: _selectedNote == null
              ? _buildEmptyEditor()
              : NoteEditorWidget(
                  key: ValueKey(_selectedNote!.id),
                  note: _selectedNote!,
                  onSave: _updateNote,
                  onDelete: _deleteNote,
                ),
        ),
      ],
    );
  }

  Widget _buildHeader({required bool showBack}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 52, 16, 12),
      decoration: const BoxDecoration(
        color: Color(AppTheme.bgSecondary),
        border: Border(bottom: BorderSide(color: Color(AppTheme.border))),
      ),
      child: Row(
        children: [
          Text(
            'Notes',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(AppTheme.textPrimary),
            ),
          ),
          const Spacer(),
          Text(
            '${_notes.length}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(AppTheme.textMuted),
            ),
          ),
          const SizedBox(width: 12),
          _buildIconButton(Icons.add, _createNote, accent: true),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      color: const Color(AppTheme.bgSecondary),
      child: TextField(
        controller: _searchCtrl,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(AppTheme.textPrimary),
        ),
        decoration: InputDecoration(
          hintText: 'Search notes…',
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(AppTheme.textMuted),
          ),
          prefixIcon: const Icon(Icons.search, size: 18, color: Color(AppTheme.textMuted)),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  color: const Color(AppTheme.textMuted),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searching = false);
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(AppTheme.bgCard),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        onTap: () => setState(() => _searching = true),
      ),
    );
  }

  Widget _buildNoteList({required bool narrow}) {
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.note_outlined, size: 48, color: Color(AppTheme.textMuted)),
            const SizedBox(height: 12),
            Text(
              _notes.isEmpty ? 'No notes yet' : 'No results',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: const Color(AppTheme.textMuted),
              ),
            ),
            if (_notes.isEmpty) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _createNote,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New note'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(AppTheme.accent),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _buildNoteCard(_filtered[i], narrow: narrow),
    );
  }

  Widget _buildNoteCard(Note note, {required bool narrow}) {
    final isSelected = !narrow && _selectedNote?.id == note.id;
    final preview = note.content.replaceAll('\n', ' ').trim();

    return GestureDetector(
      onTap: () => _openEditor(note),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(AppTheme.accentLight)
              : const Color(AppTheme.bgCard),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(AppTheme.borderAccent)
                : const Color(AppTheme.border),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title.isEmpty ? 'Untitled' : note.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: note.title.isEmpty
                          ? const Color(AppTheme.textMuted)
                          : const Color(AppTheme.textPrimary),
                    ),
                  ),
                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(AppTheme.textSecondary),
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(note.updatedAt),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(AppTheme.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _confirmDelete(note),
              child: const Icon(
                Icons.delete_outline,
                size: 16,
                color: Color(AppTheme.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyEditor() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.edit_note, size: 56, color: Color(AppTheme.textMuted)),
          const SizedBox(height: 14),
          Text(
            'Select a note or create one',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(AppTheme.textMuted),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _createNote,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Note'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppTheme.accent),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap, {bool accent = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: accent ? const Color(AppTheme.accent) : const Color(AppTheme.bgCard),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: accent ? Colors.white : const Color(AppTheme.textSecondary),
        ),
      ),
    );
  }

  void _confirmDelete(Note note) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(AppTheme.bgCard),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete note?',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(AppTheme.textPrimary),
          ),
        ),
        content: Text(
          'This cannot be undone.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(AppTheme.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: const Color(AppTheme.textSecondary)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteNote(note);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: const Color(AppTheme.danger)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline editor widget (wide layout)
// ─────────────────────────────────────────────────────────────────────────────

class NoteEditorWidget extends StatefulWidget {
  final Note note;
  final ValueChanged<Note> onSave;
  final ValueChanged<Note> onDelete;

  const NoteEditorWidget({
    super.key,
    required this.note,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<NoteEditorWidget> createState() => _NoteEditorWidgetState();
}

class _NoteEditorWidgetState extends State<NoteEditorWidget> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late Note _current;
  bool _saved = true;

  // auto-save
  final _debounce = _Debouncer(milliseconds: 800);

  @override
  void initState() {
    super.initState();
    _current = widget.note;
    _titleCtrl = TextEditingController(text: _current.title);
    _contentCtrl = TextEditingController(text: _current.content);
    _titleCtrl.addListener(_onChange);
    _contentCtrl.addListener(_onChange);
  }

  @override
  void didUpdateWidget(NoteEditorWidget old) {
    super.didUpdateWidget(old);
    if (old.note.id != widget.note.id) {
      _titleCtrl.text = widget.note.title;
      _contentCtrl.text = widget.note.content;
      _current = widget.note;
      setState(() => _saved = true);
    }
  }

  @override
  void dispose() {
    _debounce.cancel();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _onChange() {
    setState(() => _saved = false);
    _debounce.run(_save);
  }

  void _save() {
    final updated = _current.copyWith(
      title: _titleCtrl.text,
      content: _contentCtrl.text,
      updatedAt: DateTime.now().toIso8601String(),
    );
    _current = updated;
    widget.onSave(updated);
    if (mounted) setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // top bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 52, 16, 12),
          decoration: const BoxDecoration(
            color: Color(AppTheme.bgSecondary),
            border: Border(bottom: BorderSide(color: Color(AppTheme.border))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _titleCtrl,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(AppTheme.textPrimary),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Untitled',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(AppTheme.textMuted),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _saved
                    ? const Icon(Icons.check_circle, size: 16, color: Color(AppTheme.success))
                    : const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(AppTheme.accent),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _confirmDelete(context),
                child: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Color(AppTheme.danger),
                ),
              ),
            ],
          ),
        ),
        // content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _contentCtrl,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: const Color(AppTheme.textPrimary),
                height: 1.7,
              ),
              decoration: InputDecoration(
                hintText: 'Start writing…',
                hintStyle: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(AppTheme.textMuted),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(AppTheme.bgCard),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete note?',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(AppTheme.textPrimary),
          ),
        ),
        content: Text(
          'This cannot be undone.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(AppTheme.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: const Color(AppTheme.textSecondary))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete(_current);
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
// Full-screen editor page (narrow/mobile layout)
// ─────────────────────────────────────────────────────────────────────────────

class NoteEditorPage extends StatefulWidget {
  final Note note;
  final ValueChanged<Note> onSave;
  final ValueChanged<Note> onDelete;

  const NoteEditorPage({
    super.key,
    required this.note,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late Note _current;
  bool _saved = true;

  final _debounce = _Debouncer(milliseconds: 800);

  @override
  void initState() {
    super.initState();
    _current = widget.note;
    _titleCtrl = TextEditingController(text: _current.title);
    _contentCtrl = TextEditingController(text: _current.content);
    _titleCtrl.addListener(_onChange);
    _contentCtrl.addListener(_onChange);
  }

  @override
  void dispose() {
    _debounce.cancel();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _onChange() {
    setState(() => _saved = false);
    _debounce.run(_save);
  }

  void _save() {
    final updated = _current.copyWith(
      title: _titleCtrl.text,
      content: _contentCtrl.text,
      updatedAt: DateTime.now().toIso8601String(),
    );
    _current = updated;
    widget.onSave(updated);
    if (mounted) setState(() => _saved = true);
  }

  void _forceSaveAndPop() {
    _debounce.cancel();
    _save();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppTheme.bgPrimary),
      body: Column(
        children: [
          // app bar
          Container(
            padding: const EdgeInsets.fromLTRB(4, 48, 16, 8),
            decoration: const BoxDecoration(
              color: Color(AppTheme.bgSecondary),
              border: Border(bottom: BorderSide(color: Color(AppTheme.border))),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      size: 18, color: Color(AppTheme.textSecondary)),
                  onPressed: _forceSaveAndPop,
                ),
                Expanded(
                  child: TextField(
                    controller: _titleCtrl,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(AppTheme.textPrimary),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Untitled',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(AppTheme.textMuted),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _saved
                      ? const Icon(Icons.check_circle,
                          size: 16, color: Color(AppTheme.success))
                      : const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(AppTheme.accent),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _confirmDelete(context),
                  child: const Icon(Icons.delete_outline,
                      size: 20, color: Color(AppTheme.danger)),
                ),
              ],
            ),
          ),
          // word count bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: const Color(AppTheme.bgSecondary),
            child: Row(
              children: [
                Text(
                  _wordCount(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(AppTheme.textMuted),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(_current.updatedAt),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(AppTheme.textMuted),
                  ),
                ),
              ],
            ),
          ),
          // editor
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: TextField(
                controller: _contentCtrl,
                maxLines: null,
                expands: true,
                autofocus: _current.content.isEmpty,
                textAlignVertical: TextAlignVertical.top,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(AppTheme.textPrimary),
                  height: 1.75,
                ),
                decoration: InputDecoration(
                  hintText: 'Start writing…',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 15,
                    color: const Color(AppTheme.textMuted),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _wordCount() {
    final words = _contentCtrl.text.trim().split(RegExp(r'\s+'));
    final count = _contentCtrl.text.trim().isEmpty ? 0 : words.length;
    return '$count word${count == 1 ? '' : 's'}';
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '';
    try {
      return DateFormat('MMM d, h:mm a').format(DateTime.parse(iso));
    } catch (_) {
      return '';
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(AppTheme.bgCard),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete note?',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(AppTheme.textPrimary),
          ),
        ),
        content: Text(
          'This cannot be undone.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(AppTheme.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: const Color(AppTheme.textSecondary))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete(_current);
              Navigator.pop(context);
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
// Debouncer helper
// ─────────────────────────────────────────────────────────────────────────────

class _Debouncer {
  final int milliseconds;
  _Debouncer({required this.milliseconds});

  bool _active = false;

  void run(VoidCallback action) {
    _active = true;
    Future.delayed(Duration(milliseconds: milliseconds), () {
      if (_active) {
        _active = false;
        action();
      }
    });
  }

  void cancel() => _active = false;
}
