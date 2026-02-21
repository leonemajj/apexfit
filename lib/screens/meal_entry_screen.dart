import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/meal.dart';
import '../../services/meal_service.dart';

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

  late String _mealType;
  late DateTime _date;
  late TextEditingController _calController;
  late TextEditingController _notesController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.mealToEdit;

    _mealType = m?.mealType ?? _mealTypes.first;
    _date = m?.mealDate ?? DateTime.now();
    _calController = TextEditingController(text: m?.totalCalories.toString() ?? '');
    _notesController = TextEditingController(text: m?.notes ?? '');
  }

  @override
  void dispose() {
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
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final cal = int.tryParse(_calController.text.trim());
    if (cal == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('カロリーは数値で入力してください')));
      return;
    }

    setState(() => _saving = true);

    try {
      if (widget.mealToEdit == null) {
        await widget.mealService.addMeal(
          _mealType,
          _date,
          cal,
          notes: _notesController.text.trim(),
        );
      } else {
        await widget.mealService.updateMeal(
          widget.mealToEdit!.id,
          mealType: _mealType,
          mealDate: _date,
          totalCalories: cal,
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
                value: _mealType,
                decoration: const InputDecoration(labelText: '食事の種類'),
                items: _mealTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _mealType = v ?? _mealTypes.first),
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
                controller: _calController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '総カロリー(kcal)'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'カロリーを入力してください';
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
