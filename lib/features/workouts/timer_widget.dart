import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';

class SessionTimer extends StatefulWidget {
  final int initialSeconds;
  const SessionTimer({super.key, required this.initialSeconds});

  @override
  State<SessionTimer> createState() => _SessionTimerState();
}

class _SessionTimerState extends State<SessionTimer> {
  Timer? _timer;
  late int _remain;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _remain = widget.initialSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (_running) return;
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remain <= 0) {
        t.cancel();
        if (mounted) {
          setState(() => _running = false);
          _showDone();
        }
      } else {
        setState(() => _remain--);
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remain = widget.initialSeconds;
    });
  }

  void _showDone() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Palette.surface,
        title: const Text('タイマー完了'),
        content: const Text('次のセットを始めましょう'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = (_remain ~/ 60).toString().padLeft(2, '0');
    final s = (_remain % 60).toString().padLeft(2, '0');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$m:$s', style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w900, color: Palette.text)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _running ? _pause : _start,
                icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                label: Text(_running ? '一時停止' : '開始'),
                style: ElevatedButton.styleFrom(backgroundColor: _running ? Palette.warning : Palette.accent),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh),
                label: const Text('リセット'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
