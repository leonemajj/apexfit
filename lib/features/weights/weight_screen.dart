import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/apex_card.dart';
import '../../services/weight_service.dart';
import '../../models/weight.dart';

class WeightScreen extends StatefulWidget {
  final WeightService weightService;
  const WeightScreen({super.key, required this.weightService});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weight = TextEditingController();
  DateTime _date = DateTime.now();

  void _snack(String msg, {bool err = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime.now());
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final kg = double.tryParse(_weight.text.trim());
    if (kg == null) return;
    try {
      await widget.weightService.addOrUpdate(_date, kg);
      _weight.clear();
      if (mounted) FocusScope.of(context).unfocus();
      _snack('体重を記録しました');
    } catch (e) {
      _snack('失敗: $e', err: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('体重')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ApexCard(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
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
                      controller: _weight,
                      decoration: const InputDecoration(labelText: '体重 (kg)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return '体重を入力してください';
                        final n = double.tryParse(v);
                        if (n == null) return '数値で入力してください';
                        if (n <= 0) return '0より大きく';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _save, child: const Text('記録する'))),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Weight>>(
              stream: widget.weightService.streamWeights(),
              builder: (context, snap) {
                final weights = snap.data ?? [];
                if (weights.isEmpty) return const Center(child: Text('体重の記録がありません', style: AppText.muted));
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemBuilder: (context, i) {
                    final w = weights[i];
                    return ApexCard(
                      child: ListTile(
                        title: Text('${DateFormat('yyyy/MM/dd').format(w.date)}  •  ${w.weightKg} kg', style: AppText.body),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: weights.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
