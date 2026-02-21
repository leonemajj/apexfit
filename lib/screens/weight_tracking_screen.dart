import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/weight.dart';
import '../../services/weight_service.dart';

class WeightTrackingScreen extends StatefulWidget {
  final WeightService weightService;
  const WeightTrackingScreen({super.key, required this.weightService});

  @override
  State<WeightTrackingScreen> createState() => _WeightTrackingScreenState();
}

class _WeightTrackingScreenState extends State<WeightTrackingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();

  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final w = double.tryParse(_weightController.text.trim());
    if (w == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('体重は数値で入力してください')));
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.weightService.addOrUpdateWeight(_date, w);

      if (!mounted) return;
      _weightController.clear();
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('記録しました')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('記録失敗: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('yyyy/MM/dd').format(_date);

    return Scaffold(
      appBar: AppBar(title: const Text('体重記録')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickDate,
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: '日付', suffixIcon: Icon(Icons.calendar_today)),
                        controller: TextEditingController(text: dateText),
                        validator: (v) => (v == null || v.isEmpty) ? '日付を選択してください' : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: '体重(kg)'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return '体重を入力してください';
                      final n = double.tryParse(v);
                      if (n == null) return '数値を入力してください';
                      if (n <= 0) return '0より大きく入力してください';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('記録する'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: StreamBuilder<List<Weight>>(
              stream: widget.weightService.streamWeights(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) return Center(child: Text('エラー: ${snapshot.error}'));
                final list = snapshot.data ?? [];
                if (list.isEmpty) return const Center(child: Text('体重の記録がありません。'));

                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final w = list[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        title: Text('${DateFormat('yyyy/MM/dd').format(w.date)}  •  ${w.weightKg} kg'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
