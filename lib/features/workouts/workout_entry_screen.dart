import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/workout_service.dart';
import '../../models/workout.dart';

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
  late TextEditingController _dur;
  late TextEditingController _cal;
  late TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    if (widget.workoutToEdit != null) {
      final w = widget.workoutToEdit!;
      _type = w.workoutType;
      _date = w.workoutDate;
      _dur = TextEditingController(text: w.durationMinutes.toString());
      _cal = TextEditingController(text: w.totalCaloriesBurned.toString());
      _notes = TextEditingController(text: w.notes ?? '');
    } else {
      _type = _types.first;
      _date = DateTime.now();
      _dur = TextEditingController();
      _cal = TextEditingController();
      _notes = TextEditingController();
    }
  }

  @override
  void dispose() {
    _dur.dispose();
    _cal.dispose();
    _notes.dispose();
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
    final duration = int.tryParse(_dur.text.trim());
    final calories = int.tryParse(_cal.text.trim());
    if (duration == null || calories == null) return;

    if (widget.workoutToEdit != null) {
      await widget.workoutService.updateWorkout(
        widget.workoutToEdit!.id,
        workoutType: _type,
        workoutDate: _date,
        durationMinutes: duration,
        calories: calories,
        notes: _notes.text.trim(),
      );
    } else {
      await widget.workoutService.addWorkout(_type, _date, duration, calories, notes: _notes.text.trim());
    }
    if (mounted) Navigator.pop(context);
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
                items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
                decoration: const InputDecoration(labelText: '種類'),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _dur,
                decoration: const InputDecoration(labelText: '時間 (分)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return '時間を入力してください';
                  final n = int.tryParse(v);
                  if (n == null) return '数値で入力してください';
                  if (n <= 0) return '1以上で入力してください';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cal,
                decoration: const InputDecoration(labelText: '消費カロリー (kcal)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return '消費カロリーを入力してください';
                  final n = int.tryParse(v);
                  if (n == null) return '数値で入力してください';
                  if (n <= 0) return '1以上で入力してください';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'メモ (任意)'),
                maxLines: 3,
              ),
              const SizedBox(height: 18),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _save, child: const Text('保存'))),
            ],
          ),
        ),
      ),
    );
  }
}
