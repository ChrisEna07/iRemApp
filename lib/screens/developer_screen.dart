import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../database/db_helper.dart';
import '../providers/app_settings.dart';

class DeveloperScreen extends StatefulWidget {
  const DeveloperScreen({super.key});

  @override
  State<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends State<DeveloperScreen> {
  final TextEditingController _passController = TextEditingController();
  bool _isAuthorized = false;
  final DBHelper _dbHelper = DBHelper();

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

  Future<void> _exportData() async {
    try {
      final db = await _dbHelper.database;
      Map<String, dynamic> export = {
        'tasks': await db.query('tasks'),
        'grocery': await db.query('grocery'),
        'finance_transactions': await db.query('finance_transactions'),
        'finance_settings': await db.query('finance_settings'),
        'calculator_history': await db.query('calculator_history'),
      };

      String jsonStr = jsonEncode(export);
      Directory? dir;
      if (Platform.isAndroid) { dir = await getExternalStorageDirectory(); } 
      else { dir = await getApplicationDocumentsDirectory(); }
      
      String path = "${dir!.path}/iremember_backup.json";
      File file = File(path);
      await file.writeAsString(jsonStr);
      _showCentralFeedback("Exportado a: ${path.split('/').last}", Icons.download_done, Colors.green);
    } catch (e) { _showCentralFeedback("Error al exportar", Icons.error, Colors.red); }
  }

  Future<void> _importData() async {
    try {
      Directory? dir;
      if (Platform.isAndroid) { dir = await getExternalStorageDirectory(); } 
      else { dir = await getApplicationDocumentsDirectory(); }
      
      String path = "${dir!.path}/iremember_backup.json";
      File file = File(path);
      if (!await file.exists()) { _showCentralFeedback("No se encontró backup", Icons.warning, Colors.orange); return; }

      String jsonStr = await file.readAsString();
      Map<String, dynamic> data = jsonDecode(jsonStr);

      final db = await _dbHelper.database;
      await db.transaction((txn) async {
        await txn.delete('tasks');
        await txn.delete('grocery');
        await txn.delete('finance_transactions');
        await txn.delete('calculator_history');
        
        for (var row in data['tasks']) await txn.insert('tasks', row);
        for (var row in data['grocery']) await txn.insert('grocery', row);
        for (var row in data['finance_transactions']) await txn.insert('finance_transactions', row);
        for (var row in data['calculator_history']) await txn.insert('calculator_history', row);
        if (data['finance_settings'].isNotEmpty) {
           await txn.update('finance_settings', data['finance_settings'][0], where: 'id = 1');
        }
      });
      _showCentralFeedback("¡Importación Exitosa!", Icons.cloud_done, Colors.blue);
    } catch (e) { _showCentralFeedback("Error al importar", Icons.error, Colors.red); }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthorized) {
      return Scaffold(
        appBar: AppBar(title: const Text("Modo Super Desarrollador")),
        body: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              TextField(controller: _passController, obscureText: true, decoration: const InputDecoration(labelText: "Clave de Acceso", border: OutlineInputBorder())),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_passController.text == "ChrizDev3008") {
                    setState(() => _isAuthorized = true);
                    _showCentralFeedback("¡Acceso Concedido!", Icons.admin_panel_settings, Colors.blue);
                  } else {
                    _showCentralFeedback("Clave Incorrecta", Icons.lock_open, Colors.red);
                  }
                },
                child: const Text("ENTRAR"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Panel de Control - ChrizDev")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildDevCard("Base de Datos", "Borra todo el historial y ajustes.", Icons.delete_forever, Colors.red, () async {
            bool? confirm = await showDialog(context: context, builder: (context) => AlertDialog(title: const Text("¿Reiniciar App?"), content: const Text("Se borrarán todas las tareas, finanzas y ajustes."), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("SÍ, BORRAR TODO"))]));
            if (confirm == true) { await _dbHelper.clearAllData(); _showCentralFeedback("App Reiniciada", Icons.cleaning_services, Colors.orange); }
          }),
          _buildDevCard("Exportar Datos", "Crea un archivo JSON con toda tu información.", Icons.upload_file, Colors.green, _exportData),
          _buildDevCard("Importar Datos", "Recupera información desde iremember_backup.json", Icons.file_download, Colors.blue, _importData),
        ],
      ),
    );
  }

  Widget _buildDevCard(String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub),
        onTap: onTap,
      ),
    );
  }
}
