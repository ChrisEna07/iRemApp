import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../database/db_helper.dart';
import '../../providers/app_settings.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final DBHelper _dbHelper = DBHelper();
  double _savingsGoal = 0;
  double _totalIncome = 0;
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

    setState(() {
      _savingsGoal = settings['savings_goal'] ?? 0;
      _totalIncome = settings['total_income'] ?? 0;
      _transactions = trans;
      _spentNeeds = needs;
      _spentWants = wants;
      _spentSavings = savings;
    });
  }

  String _formatCurrency(double amount, String type) {
    if (type == "COP") {
      // Formato COP: 0.000.000 (sin decimales usualmente o con puntos como separador de miles)
      return NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(amount).replaceAll(',', '.');
    } else if (type == "VES") {
      return NumberFormat.currency(locale: 'es_VE', symbol: 'Bs', decimalDigits: 2).format(amount);
    } else {
      // USD
      return NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2).format(amount);
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("ENTENDIDO"))],
      ),
    );
  }

  void _addTransactionDialog() {
    final amountController = TextEditingController();
    String type = 'expense';
    String category = 'needs';
    final appSettings = context.read<AppSettings>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Agregar Movimiento"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: type,
                items: const [
                  DropdownMenuItem(value: 'income', child: Text("Ingreso (+)")),
                  DropdownMenuItem(value: 'expense', child: Text("Gasto (-)")),
                ],
                onChanged: (val) => setDialogState(() => type = val!),
              ),
              if (type == 'expense')
                DropdownButton<String>(
                  value: category,
                  items: const [
                    DropdownMenuItem(value: 'needs', child: Text("Necesidades (50%)")),
                    DropdownMenuItem(value: 'wants', child: Text("Gustos (30%)")),
                    DropdownMenuItem(value: 'savings', child: Text("Ahorro/Deuda (20%)")),
                  ],
                  onChanged: (val) => setDialogState(() => category = val!),
                ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Monto (${appSettings.currency})"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
            TextButton(
              onPressed: () async {
                double amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0) return;

                if (type == 'income') {
                  await _dbHelper.updateFinanceSettings(_savingsGoal, _totalIncome + amount);
                  Navigator.pop(context);
                } else {
                  double limit = 0;
                  double currentSpent = 0;
                  if (category == 'needs') { limit = _totalIncome * 0.5; currentSpent = _spentNeeds; }
                  if (category == 'wants') { limit = _totalIncome * 0.3; currentSpent = _spentWants; }
                  if (category == 'savings') { limit = _totalIncome * 0.2; currentSpent = _spentSavings; }

                  if (currentSpent + amount > limit) {
                    _showAlert("¡ALERTA DE PRESUPUESTO!", "Este gasto de ${_formatCurrency(amount, appSettings.currency)} supera el límite de tu presupuesto.");
                  }
                  
                  await _dbHelper.addTransaction(type, amount, category);
                  Navigator.pop(context);
                }
                _loadData();
              },
              child: const Text("GUARDAR"),
            ),
          ],
        ),
      ),
    );
  }

  void _setGoalDialog() {
    final goalController = TextEditingController(text: _savingsGoal.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Meta de Ahorro"),
        content: TextField(
          controller: goalController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Monto deseado"),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _dbHelper.updateFinanceSettings(double.tryParse(goalController.text) ?? 0, _totalIncome);
              Navigator.pop(context);
              _loadData();
            },
            child: const Text("DEFINIR"),
          ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text("Disponible: ${_formatCurrency(remaining, cur)}", style: TextStyle(color: remaining < 0 ? Colors.red : Colors.grey, fontSize: 11)),
              ],
            ),
            Text("${(percent * 100).toStringAsFixed(1)}%", style: TextStyle(color: percent >= 1.0 ? Colors.red : color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(height: 12, width: double.infinity, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6))),
            FractionallySizedBox(
              widthFactor: percent,
              child: Container(height: 12, decoration: BoxDecoration(color: percent >= 1.0 ? Colors.red : color, borderRadius: BorderRadius.circular(6))),
            ),
          ],
        ),
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

    return Scaffold(
      appBar: AppBar(title: const Text("Finanzas 50/30/20")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text("Capital Total Ingresado", style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 5),
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _setGoalDialog,
                    icon: const Icon(Icons.stars, color: Colors.purple),
                    label: Text("Meta: ${_formatCurrency(_savingsGoal, appSettings.currency)}"),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  ),
                ),
              ],
            ),
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
                          onLongPress: () async {
                            await _dbHelper.deleteTransaction(t['id']);
                            _loadData();
                          },
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTransactionDialog,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Movimiento", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
