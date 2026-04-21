import 'package:flutter/material.dart';
import '../../database/db_helper.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _output = "0";
  String _expression = "";
  double _num1 = 0;
  String _operand = "";
  final DBHelper _dbHelper = DBHelper();
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _dbHelper.getCalcHistory();
    setState(() => _history = history);
  }

  void _buttonPressed(String buttonText) async {
    setState(() {
      if (buttonText == "C") {
        _output = "0";
        _expression = "";
        _num1 = 0;
        _operand = "";
      } else if (buttonText == "+" || buttonText == "-" || buttonText == "×" || buttonText == "÷") {
        _num1 = double.tryParse(_output) ?? 0;
        _operand = buttonText;
        _expression = "$_output $buttonText ";
        _output = "0";
      } else if (buttonText == "=") {
        double num2 = double.tryParse(_output) ?? 0;
        double result = 0;
        if (_operand == "+") result = _num1 + num2;
        if (_operand == "-") result = _num1 - num2;
        if (_operand == "×") result = _num1 * num2;
        if (_operand == "÷") {
          if (num2 != 0) result = _num1 / num2;
          else { _output = "Error"; return; }
        }
        
        String finalResult = result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 2);
        String entry = "$_num1 $_operand $num2 = $finalResult";
        _dbHelper.addCalcHistory(entry).then((_) => _loadHistory());
        _output = finalResult;
        _expression = "";
      } else {
        if (_output == "0") _output = buttonText;
        else _output = _output + buttonText;
      }
    });
  }

  Widget _buildButton(String text, {Color? color}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(20),
            backgroundColor: color ?? Colors.grey[200],
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => _buttonPressed(text),
          child: Text(text, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calculadora"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Column(
                  children: [
                    ListTile(
                      title: const Text("Limpiar Historial", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.delete_sweep, color: Colors.red),
                      onTap: () async {
                        await _dbHelper.clearCalcHistory();
                        _loadHistory();
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _history.length,
                        itemBuilder: (context, index) => ListTile(
                          title: Text(_history[index]),
                          onTap: () {
                            setState(() => _output = _history[index].split('= ').last);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(child: Container(alignment: Alignment.bottomRight, padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.end, children: [Text(_expression, style: const TextStyle(fontSize: 20, color: Colors.grey)), Text(_output, style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold))]))),
          Column(children: [
            Row(children: [_buildButton("7"), _buildButton("8"), _buildButton("9"), _buildButton("÷", color: Colors.orange)]),
            Row(children: [_buildButton("4"), _buildButton("5"), _buildButton("6"), _buildButton("×", color: Colors.orange)]),
            Row(children: [_buildButton("1"), _buildButton("2"), _buildButton("3"), _buildButton("-", color: Colors.orange)]),
            Row(children: [_buildButton("C", color: Colors.redAccent), _buildButton("0"), _buildButton("=", color: Colors.green), _buildButton("+", color: Colors.orange)]),
          ]),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
