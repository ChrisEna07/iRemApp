import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_settings.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final TextEditingController _usdController = TextEditingController();
  final TextEditingController _vesRateController = TextEditingController();
  final TextEditingController _copRateController = TextEditingController();
  
  double _vesResult = 0;
  double _copResult = 0;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppSettings>();
    _vesRateController.text = settings.rateVES.toString();
    _copRateController.text = settings.rateCOP.toString();
  }

  void _convert() {
    double usd = double.tryParse(_usdController.text) ?? 0;
    double rateVES = double.tryParse(_vesRateController.text) ?? 0;
    double rateCOP = double.tryParse(_copRateController.text) ?? 0;
    
    setState(() {
      _vesResult = usd * rateVES;
      _copResult = usd * rateCOP;
    });
    
    // Guardamos las tasas nuevas para la próxima vez
    context.read<AppSettings>().updateRates(rateVES, rateCOP);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text("Conversor Exacto")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              "Configura las tasas actuales si no tienes internet:",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _vesRateController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Tasa USD/VES", border: OutlineInputBorder()),
                    onChanged: (_) => _convert(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _copRateController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Tasa USD/COP", border: OutlineInputBorder()),
                    onChanged: (_) => _convert(),
                  ),
                ),
              ],
            ),
            const Divider(height: 40),
            TextField(
              controller: _usdController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: "Monto en Dólares (USD)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              onChanged: (_) => _convert(),
            ),
            const SizedBox(height: 30),
            _buildResultCard("Resultado en Bolívares (VES)", _vesResult, Colors.blue),
            const SizedBox(height: 15),
            _buildResultCard("Resultado en Pesos (COP)", _copResult, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String label, double value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            value.toStringAsFixed(2),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
