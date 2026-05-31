import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_theme.dart';
import '../utils/data_store.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> with SingleTickerProviderStateMixin {
  Timer? _timer;
  bool _running = false;
  String _mode = 'work';
  int _secondsLeft = 25 * 60;
  int _totalSeconds = 25 * 60;
  int _sessionNum = 1;
  int _todaySessions = 0;

  int _workDur = 25;
  int _shortDur = 5;
  int _longDur = 15;
  int _target = 4;

  final _taskCtrl = TextEditingController();

  final _modeColors = {
    'work': AppTheme.danger,
    'short': AppTheme.success,
    'long': AppTheme.info,
  };

  final _modeLabels = {
    'work': 'Focus Time',
    'short': 'Short Break',
    'long': 'Long Break',
  };

  @override
  void initState() {
    super.initState();
    _loadTodaySessions();
  }

  void _loadTodaySessions() {
    final log = DataStore.getList('pomodoro_log');
    _todaySessions = log.where((l) => l['date'] == DataStore.todayStr() && l['type'] == 'work').length;
    setState(() {});
  }

  void _setMode(String mode) {
    _stopTimer();
    _mode = mode;
    final durations = {'work': _workDur, 'short': _shortDur, 'long': _longDur};
    _secondsLeft = (durations[mode] ?? 25) * 60;
    _totalSeconds = _secondsLeft;
    setState(() {});
  }

  void _toggleTimer() {
    if (_running) {
      _stopTimer();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      setState(() => _running = true);
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _resetTimer() {
    _stopTimer();
    _setMode(_mode);
  }

  Future<void> _tick() async {
    if (_secondsLeft <= 0) {
      _stopTimer();
      await _onSessionComplete();
      return;
    }
    setState(() => _secondsLeft--);
  }

  Future<void> _onSessionComplete() async {
    final log = DataStore.getList('pomodoro_log');
    log.insert(0, {
      'id': DataStore.genId(),
      'type': _mode,
      'date': DataStore.todayStr(),
      'time': TimeOfDay.now().format(context),
      'task': _taskCtrl.text,
    });
    await DataStore.setList('pomodoro_log', log);

    if (_mode == 'work') {
      setState(() {
        _todaySessions++;
        _sessionNum++;
      });
      if (_sessionNum > _target) {
        setState(() => _sessionNum = 1);
        _setMode('long');
      } else {
        _setMode('short');
      }
    } else {
      _setMode('work');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_mode == 'work' ? '🎉 Session done! Take a break.' : '⏱️ Break over! Time to focus.'),
        backgroundColor: AppTheme.bgCard,
      ));
    }
  }

  String get _timeDisplay {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  double get _progress => _totalSeconds > 0 ? _secondsLeft / _totalSeconds : 1;

  @override
  void dispose() {
    _timer?.cancel();
    _taskCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _modeColors[_mode] ?? AppTheme.accent;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('⏱️ Pomodoro Timer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Mode tabs
            Container(
              padding: const EdgeInsets.all(6),
              decoration: AppTheme.cardDecoration(),
              child: Row(
                children: [
                  for (final m in [('work', '🍅 Focus'), ('short', '☕ Short'), ('long', '🌙 Long')])
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _setMode(m.$1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _mode == m.$1 ? color : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppTheme.radius),
                          ),
                          child: Text(m.$2, textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                              color: _mode == m.$1 ? Colors.white : AppTheme.textMuted)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Timer ring
            SizedBox(
              width: 250,
              height: 250,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 10,
                      backgroundColor: AppTheme.bgCard,
                      color: color,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_timeDisplay,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 52, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                      Text(_modeLabels[_mode] ?? '',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ControlBtn(icon: Icons.replay_rounded, onTap: _resetTimer),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: _toggleTimer,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color, color.withOpacity(0.7)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 16)],
                    ),
                    child: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(width: 20),
                _ControlBtn(icon: Icons.skip_next_rounded, onTap: () {
                  _stopTimer();
                  setState(() => _secondsLeft = 0);
                  _onSessionComplete();
                }),
              ],
            ),
            const SizedBox(height: 16),
            Text('Session $_sessionNum of $_target  •  Today: $_todaySessions sessions',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            const SizedBox(height: 24),

            // Current task
            TextField(
              controller: _taskCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.work_outline_rounded, color: AppTheme.textMuted),
                hintText: 'What are you working on?',
                labelText: 'Current Task',
              ),
            ),
            const SizedBox(height: 24),

            // Settings
            Container(
              decoration: AppTheme.cardDecoration(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('⚙️ SETTINGS', style: AppTheme.labelStyle),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _DurField('Focus (min)', _workDur, (v) => setState(() => _workDur = v))),
                    const SizedBox(width: 10),
                    Expanded(child: _DurField('Short Break', _shortDur, (v) => setState(() => _shortDur = v))),
                    const SizedBox(width: 10),
                    Expanded(child: _DurField('Long Break', _longDur, (v) => setState(() => _longDur = v))),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Session log
            _SessionLog(),
          ],
        ),
      ),
    );
  }

  Widget _DurField(String label, int val, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: val.toString(),
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
          onChanged: (v) { final n = int.tryParse(v); if (n != null) onChanged(n); },
        ),
      ],
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ControlBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.border),
        ),
        child: Icon(icon, color: AppTheme.textSecondary, size: 22),
      ),
    );
  }
}

class _SessionLog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final log = DataStore.getList('pomodoro_log').take(8).toList();
    if (log.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📊 SESSION LOG', style: AppTheme.labelStyle),
          const SizedBox(height: 10),
          ...log.map((l) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Text(l['type'] == 'work' ? '🍅' : l['type'] == 'short' ? '☕' : '🌙',
                style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Text(l['type'] as String? ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const Spacer(),
              if ((l['task'] as String? ?? '').isNotEmpty)
                Flexible(child: Text(l['task'] as String,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Text(l['time'] as String? ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ]),
          )),
        ],
      ),
    );
  }
}
