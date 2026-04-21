import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../database/db_helper.dart';
import '../../providers/app_settings.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _FinanceScreenContent();
  }
}

class _FinanceScreenContent extends StatefulWidget {
  const _FinanceScreenContent();
  @override
  State<_FinanceScreenContent> createState() => _FinanceScreenContentState();
}

class _FinanceScreenContentState extends State<_FinanceScreenContent> {
  final DBHelper _dbHelper = DBHelper();
  double _savingsGoal = 0;
  String _goalName = "Mi Meta";
  double _totalIncome = 0;
  double _currentSavings = 0;
  List<Map<String, dynamic>> _transactions = [];

  double _spentNeeds = 0;
  double _spentWants = 0;
  double _spentSavings = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final settings = await _dbHelper.getFinanceSettings();
    final trans = await _dbHelper.getTransactions();
    
    double needs = 0, wants = 0, savings = 0;
    for (var t in trans) {
      if (t['type'] == 'expense') {
        if (t['category'] == 'needs') needs += t['amount'];
        if (t['category'] == 'wants') wants += t['amount'];
        if (t['category'] == 'savings') savings += t['amount'];
      }
    }

    if (mounted) {
      setState(() {
        _savingsGoal = (settings['savings_goal'] as num).toDouble();
        _goalName = settings['savings_goal_name'] ?? "Mi Meta";
        _totalIncome = (settings['total_income'] as num).toDouble();
        _currentSavings = (settings['current_savings'] as num).toDouble();
        _transactions = trans;
        _spentNeeds = needs;
        _spentWants = wants;
        _spentSavings = savings;
      });
    }
  }

  void _showCentralFeedback(String message, IconData icon, Color color) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(milliseconds: 1500), () { if (Navigator.canPop(context)) Navigator.pop(context); });
        return Center(
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, spreadRadius: 5)]),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 60, color: color),
                      const SizedBox(height: 15),
                      Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black, decoration: TextDecoration.none, fontFamily: 'Roboto')),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatCurrency(double amount, String type) {
    if (type == "COP") return NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(amount).replaceAll(',', '.');
    if (type == "VES") return NumberFormat.currency(locale: 'es_VE', symbol: 'Bs', decimalDigits: 2).format(amount);
    return NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2).format(amount);
  }

  void _showAlert(String title, String message) {
    showDialog(context: context, builder: (context) => AlertDialog(title: Text(title, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), content: Text(message), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("ENTENDIDO"))]));
  }

  void _addTransactionDialog() {
    final amountController = TextEditingController();
    String type = 'expense';
    String category = 'needs';
    bool goToGoal = false;
    final appSettings = context.read<AppSettings>();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Nuevo Movimiento"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: "Tipo"), items: const [DropdownMenuItem(value: 'income', child: Text("Ingreso (+)")), DropdownMenuItem(value: 'expense', child: Text("Gasto (-)"))], onChanged: (val) => setDialogState(() => type = val!)),
              if (type == 'income') CheckboxListTile(title: const Text("Destinar a la Meta de Ahorro", style: TextStyle(fontSize: 12)), value: goToGoal, onChanged: (val) => setDialogState(() => goToGoal = val!)),
              if (type == 'expense') DropdownButtonFormField<String>(value: category, decoration: const InputDecoration(labelText: "Categoría"), items: const [DropdownMenuItem(value: 'needs', child: Text("Necesidades (50%)")), DropdownMenuItem(value: 'wants', child: Text("Gustos (30%)")), DropdownMenuItem(value: 'savings', child: Text("Ahorro/Deuda (20%)"))], onChanged: (val) => setDialogState(() => category = val!)),
              TextField(controller: amountController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Monto (${appSettings.currency})")),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                double amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0) return;
                setDialogState(() => isSaving = true);
                try {
                  if (type == 'income') {
                    if (goToGoal) await _dbHelper.updateFinanceSettings(_savingsGoal, _totalIncome, currentSavings: _currentSavings + amount, goalName: _goalName);
                    else await _dbHelper.updateFinanceSettings(_savingsGoal, _totalIncome + amount, currentSavings: _currentSavings, goalName: _goalName);
                    Navigator.of(context).pop();
                    _showCentralFeedback("¡Ingreso Depositado!", Icons.account_balance_wallet, Colors.green);
                  } else {
                    double limit = 0;
                    if (category == 'needs') limit = _totalIncome * 0.5 - _spentNeeds;
                    if (category == 'wants') limit = _totalIncome * 0.3 - _spentWants;
                    if (category == 'savings') limit = _totalIncome * 0.2 - _spentSavings;
                    if (amount > limit) _showAlert("¡ALERTA!", "Superas el presupuesto de esta categoría.");
                    await _dbHelper.addTransaction(type, amount, category);
                    Navigator.of(context).pop();
                    _showCentralFeedback("¡Gasto Realizado!", Icons.shopping_bag, Colors.orange);
                  }
                  await _loadData();
                } catch (e) { setDialogState(() => isSaving = false); }
              },
              child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("GUARDAR"),
            ),
          ],
        ),
      ),
    );
  }

  void _setGoalDialog({bool isEdit = false}) {
    final goalController = TextEditingController(text: isEdit ? _savingsGoal.toString() : "");
    final nameController = TextEditingController(text: isEdit ? _goalName : "");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? "Editar Meta" : "Nueva Meta de Ahorro"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nombre de la Meta (ej: Mi Carro)")),
            const SizedBox(height: 10),
            TextField(controller: goalController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Monto deseado")),
          ],
        ),
        actions: [
          if (isEdit) TextButton(onPressed: () async {
            await _dbHelper.updateFinanceSettings(0, _totalIncome, currentSavings: 0, goalName: "Mi Meta");
            Navigator.pop(context);
            _showCentralFeedback("¡Meta Eliminada!", Icons.delete_forever, Colors.red);
            _loadData();
          }, child: const Text("ELIMINAR", style: TextStyle(color: Colors.red))),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () async {
              double newGoal = double.tryParse(goalController.text) ?? 0;
              String newName = nameController.text.isEmpty ? "Mi Meta" : nameController.text;
              await _dbHelper.updateFinanceSettings(newGoal, _totalIncome, currentSavings: _currentSavings, goalName: newName);
              if (mounted) Navigator.pop(context);
              _showCentralFeedback(isEdit ? "¡Meta Actualizada!" : "¡Meta Definida!", Icons.stars, Colors.purple);
              await _loadData();
            },
            child: Text(isEdit ? "GUARDAR" : "DEFINIR"),
          ),
        ],
      ),
    );
  }

  void _showGoalDetail() {
    final appSettings = context.read<AppSettings>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_goalName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars, size: 80, color: Colors.purple),
            const SizedBox(height: 20),
            Text("Objetivo: ${_formatCurrency(_savingsGoal, appSettings.currency)}", style: const TextStyle(fontSize: 16)),
            Text("Ahorrado: ${_formatCurrency(_currentSavings, appSettings.currency)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 10),
            Text("Faltan: ${_formatCurrency(_savingsGoal - _currentSavings, appSettings.currency)}", style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); _setGoalDialog(isEdit: true); }, child: const Text("EDITAR")),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CERRAR")),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double spent, double limit, Color color, String cur) {
    double percent = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    double remaining = limit - spent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Text("Disponible: ${_formatCurrency(remaining, cur)}", style: TextStyle(color: remaining < 0 ? Colors.red : Colors.grey, fontSize: 11))]),
          Text("${(percent * 100).toStringAsFixed(1)}%", style: TextStyle(color: percent >= 1.0 ? Colors.red : color, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        Stack(children: [Container(height: 12, width: double.infinity, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6))), FractionallySizedBox(widthFactor: percent, child: Container(height: 12, decoration: BoxDecoration(color: percent >= 1.0 ? Colors.red : color, borderRadius: BorderRadius.circular(6))))]),
        const SizedBox(height: 15),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    double limitNeeds = _totalIncome * 0.5;
    double limitWants = _totalIncome * 0.3;
    double limitSavings = _totalIncome * 0.2;
    double goalPercent = _savingsGoal > 0 ? (_currentSavings / _savingsGoal).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text("Finanzas 50/30/20")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_savingsGoal > 0) GestureDetector(
              onTap: _showGoalDetail,
              child: Card(
                color: Colors.purple[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text("Meta: $_goalName 🌟", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 16), overflow: TextOverflow.ellipsis)),
                          Text("${(goalPercent * 100).toStringAsFixed(1)}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(value: goalPercent, minHeight: 15, backgroundColor: Colors.white, valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple), borderRadius: BorderRadius.circular(10)),
                      const SizedBox(height: 5),
                      Text("${_formatCurrency(_currentSavings, appSettings.currency)} de ${_formatCurrency(_savingsGoal, appSettings.currency)}", style: const TextStyle(fontSize: 12, color: Colors.purple)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text("Capital Total Ingresado", style: TextStyle(color: Colors.grey, fontSize: 14)),
                    Text(_formatCurrency(_totalIncome, appSettings.currency), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
                    const Divider(height: 40),
                    _buildProgressBar("Necesidades (Max ${_formatCurrency(limitNeeds, appSettings.currency)})", _spentNeeds, limitNeeds, Colors.blue, appSettings.currency),
                    _buildProgressBar("Gustos (Max ${_formatCurrency(limitWants, appSettings.currency)})", _spentWants, limitWants, Colors.orange, appSettings.currency),
                    _buildProgressBar("Ahorro (Max ${_formatCurrency(limitSavings, appSettings.currency)})", _spentSavings, limitSavings, Colors.purple, appSettings.currency),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),
            Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () => _setGoalDialog(isEdit: _savingsGoal > 0), icon: Icon(_savingsGoal > 0 ? Icons.edit : Icons.stars, color: Colors.purple), label: Text(_savingsGoal > 0 ? "Gestionar Meta" : "Nueva Meta"), style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)))))]),
            const SizedBox(height: 30),
            const Align(alignment: Alignment.centerLeft, child: Text("Transacciones", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 15),
            _transactions.isEmpty
                ? const Opacity(opacity: 0.5, child: Padding(padding: EdgeInsets.all(40), child: Text("Sin transacciones")))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final t = _transactions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Icon(Icons.receipt_long, color: t['category'] == 'needs' ? Colors.blue : t['category'] == 'wants' ? Colors.orange : Colors.purple),
                          title: Text(t['category'] == 'needs' ? "Necesidad" : t['category'] == 'wants' ? "Gusto" : "Ahorro"),
                          subtitle: Text(t['date'].substring(0, 10)),
                          trailing: Text("-${_formatCurrency(t['amount'], appSettings.currency)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          onLongPress: () async { await _dbHelper.deleteTransaction(t['id']); _loadData(); },
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _addTransactionDialog, backgroundColor: Colors.green, icon: const Icon(Icons.add, color: Colors.white), label: const Text("Movimiento", style: TextStyle(color: Colors.white))),
    );
  }
}
