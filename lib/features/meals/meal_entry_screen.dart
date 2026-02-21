import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/meal_service.dart';
import '../../models/meal.dart';

class MealEntryScreen extends StatefulWidget {
  final MealService mealService;
  final Meal? mealToEdit;

  const MealEntryScreen({super.key, required this.mealService, this.mealToEdit});

  @override
  State<MealEntryScreen> createState() => _MealEntryScreenState();
}

class _MealEntryScreenState extends State<MealEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mealTypes = const ['朝食', '昼食', '夕食', '間食', 'その他'];
  late String _type;
  late DateTime _date;
  late TextEditingController _cal;
  late TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    if (widget.mealToEdit != null) {
      final m = widget.mealToEdit!;
      _type = m.mealType;
      _date = m.mealDate;
      _cal = TextEditingController(text: m.totalCalories.toString());
      _notes = TextEditingController(text: m.notes ?? '');
    } else {
      _type = _mealTypes.first;
      _date = DateTime.now();
      _cal = TextEditingController();
      _notes = TextEditingController();
    }
  }

  @override
  void dispose() {
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
    final calories = int.tryParse(_cal.text.trim());
    if (calories == null) return;

    if (widget.mealToEdit != null) {
      await widget.mealService.updateMeal(
        widget.mealToEdit!.id,
        mealType: _type,
        mealDate: _date,
        totalCalories: calories,
        notes: _notes.text.trim(),
      );
    } else {
      await widget.mealService.addMeal(_type, _date, calories, notes: _notes.text.trim());
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.mealToEdit == null ? '食事を追加' : '食事を編集';
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
                items: _mealTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
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
                controller: _cal,
                decoration: const InputDecoration(labelText: '総カロリー (kcal)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'カロリーを入力してください';
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
