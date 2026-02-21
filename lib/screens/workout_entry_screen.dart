import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/workout.dart';
import '../../services/workout_service.dart';

class WorkoutEntryScreen extends StatefulWidget {
  final WorkoutService workoutService;
  final Workout? workoutToEdit;

  const WorkoutEntryScreen({super.key, required this.workoutService, this.workoutToEdit});

  @override
  State<WorkoutEntryScreen> createState() => _WorkoutEntryScreenState();
}

class _WorkoutEntryScreenState extends State<WorkoutEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  final _types = const ['筋トレ', '有酸素運動', 'ストレッチ', 'その他'];

  late String _type;
  late DateTime _date;
  late TextEditingController _durationController;
  late TextEditingController _calController;
  late TextEditingController _notesController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final w = widget.workoutToEdit;

    _type = w?.workoutType ?? _types.first;
    _date = w?.workoutDate ?? DateTime.now();
    _durationController = TextEditingController(text: w?.durationMinutes.toString() ?? '');
    _calController = TextEditingController(text: w?.totalCaloriesBurned.toString() ?? '');
    _notesController = TextEditingController(text: w?.notes ?? '');
  }

  @override
  void dispose() {
    _durationController.dispose();
    _calController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final duration = int.tryParse(_durationController.text.trim());
    final cal = int.tryParse(_calController.text.trim());
    if (duration == null || cal == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('時間/カロリーは数値で入力してください')));
      return;
    }

    setState(() => _saving = true);
    try {
      if (widget.workoutToEdit == null) {
        await widget.workoutService.addWorkout(
          _type,
          _date,
          duration,
          cal,
          notes: _notesController.text.trim(),
        );
      } else {
        await widget.workoutService.updateWorkout(
          widget.workoutToEdit!.id,
          workoutType: _type,
          workoutDate: _date,
          durationMinutes: duration,
          totalCaloriesBurned: cal,
          notes: _notesController.text.trim(),
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失敗: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.workoutToEdit == null ? 'ワークアウトを追加' : 'ワークアウトを編集';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: '種類'),
                items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _type = v ?? _types.first),
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: '日付', suffixIcon: Icon(Icons.calendar_today)),
                    controller: TextEditingController(text: DateFormat('yyyy/MM/dd').format(_date)),
                    validator: (v) => (v == null || v.isEmpty) ? '日付を選択してください' : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '時間(分)'),
                validator: (v) {
                  if (v == null || v.isEmpty) return '時間を入力してください';
                  final n = int.tryParse(v);
                  if (n == null) return '数値を入力してください';
                  if (n <= 0) return '1以上で入力してください';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _calController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '消費カロリー(kcal)'),
                validator: (v) {
                  if (v == null || v.isEmpty) return '消費カロリーを入力してください';
                  final n = int.tryParse(v);
                  if (n == null) return '数値を入力してください';
                  if (n <= 0) return '1以上で入力してください';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'メモ(任意)'),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('保存'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
