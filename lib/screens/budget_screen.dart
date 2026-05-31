import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../utils/app_theme.dart';
import '../utils/data_store.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  List<Map<String, dynamic>> _txs = [];
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => _txs = DataStore.getList('transactions'));

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'all') return _txs;
    return _txs.where((t) => t['type'] == _filter).toList();
  }

  double get _income => _txs.where((t) => t['type'] == 'income').fold(0.0, (s, t) => s + (t['amount'] as num));
  double get _expense => _txs.where((t) => t['type'] == 'expense').fold(0.0, (s, t) => s + (t['amount'] as num));
  double get _balance => _income - _expense;

  String _fmt(double v) => NumberFormat('#,##0.00', 'en_IN').format(v);

  void _addTransaction() {
    String type = 'expense';
    final amtCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'Food & Dining';
    String date = DataStore.todayStr();

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
                Text('💰 Add Transaction',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, color: AppTheme.textMuted), onPressed: () => Navigator.pop(ctx)),
              ]),
              const SizedBox(height: 12),
              // Type toggle
              Row(children: [
                for (final t in [('income', '💵 Income'), ('expense', '💸 Expense')])
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: t.$1 == 'income' ? 8 : 0),
                      child: GestureDetector(
                        onTap: () => setS(() => type = t.$1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: type == t.$1 ? AppTheme.accentLight : Colors.transparent,
                            border: Border.all(color: type == t.$1 ? AppTheme.borderAccent : AppTheme.border),
                            borderRadius: BorderRadius.circular(AppTheme.radius),
                          ),
                          child: Text(t.$2, textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: type == t.$1 ? AppTheme.accent2 : AppTheme.textMuted)),
                        ),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 12),
              TextField(controller: amtCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Amount (₹) *', prefixText: '₹ ')),
              const SizedBox(height: 10),
              TextField(controller: descCtrl, style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Description *', hintText: 'What is this for?')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: category,
                dropdownColor: AppTheme.bgCard,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['Food & Dining', 'Transport', 'Shopping', 'Entertainment', 'Health', 'Education',
                  'Salary', 'Freelance', 'Investment', 'Other']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setS(() => category = v!),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final amt = double.tryParse(amtCtrl.text);
                    final desc = descCtrl.text.trim();
                    if (amt == null || amt <= 0 || desc.isEmpty) return;
                    _txs.insert(0, {
                      'id': DataStore.genId(), 'type': type, 'amount': amt,
                      'desc': desc, 'category': category, 'date': date,
                      'createdAt': DateTime.now().toIso8601String(),
                    });
                    DataStore.setList('transactions', _txs);
                    setState(() {});
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Transaction'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('💰 Budget Tracker')),
      body: Column(
        children: [
          // Summary cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(child: _SummaryCard('Income', '₹${_fmt(_income)}', AppTheme.success)),
              const SizedBox(width: 8),
              Expanded(child: _SummaryCard('Expenses', '₹${_fmt(_expense)}', AppTheme.danger)),
              const SizedBox(width: 8),
              Expanded(child: _SummaryCard('Balance', '₹${_fmt(_balance.abs())}',
                _balance >= 0 ? AppTheme.accent2 : AppTheme.danger)),
            ]),
          ),

          // Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              for (final f in [('all', 'All'), ('income', 'Income'), ('expense', 'Expenses')])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _filter == f.$1 ? AppTheme.accentLight : Colors.transparent,
                        border: Border.all(color: _filter == f.$1 ? AppTheme.borderAccent : AppTheme.border),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(f.$2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                        color: _filter == f.$1 ? AppTheme.accent2 : AppTheme.textSecondary)),
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 10),

          // Transactions list
          Expanded(
            child: _filtered.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('💰', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('No transactions yet', style: TextStyle(color: AppTheme.textMuted)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final t = _filtered[i];
                    final isIncome = t['type'] == 'income';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: AppTheme.cardDecoration(),
                      child: ListTile(
                        leading: Text(isIncome ? '💵' : '💸', style: const TextStyle(fontSize: 24)),
                        title: Text(t['desc'] as String? ?? '',
                          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text('${t['category']} · ${t['date']}',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${isIncome ? '+' : '-'}₹${_fmt((t['amount'] as num).toDouble())}',
                              style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w700,
                                color: isIncome ? AppTheme.success : AppTheme.danger)),
                            IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.textMuted),
                              onPressed: () {
                                _txs.removeWhere((x) => x['id'] == t['id']);
                                DataStore.setList('transactions', _txs);
                                setState(() {});
                              }),
                          ],
                        ),
                      ),
                    );
                  }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTransaction,
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Transaction'),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Column(children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
        const SizedBox(height: 4),
        FittedBox(child: Text(value, style: GoogleFonts.jetBrainsMono(
          fontSize: 16, fontWeight: FontWeight.w700, color: color))),
      ]),
    );
  }
}
