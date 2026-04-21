import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../providers/app_settings.dart';
import '../database/db_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = context.read<AppSettings>().userName;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    
    return Scaffold(
      appBar: AppBar(title: const Text("Configuración")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("PERFIL", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: "Tu nombre", border: OutlineInputBorder()),
            onChanged: (val) => settings.setUserName(val),
          ),
          const SizedBox(height: 20),
          const Text("ZONA HORARIA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          DropdownButtonFormField<String>(
            value: settings.timezone,
            items: const [
              DropdownMenuItem(value: "America/Caracas", child: Text("Venezuela (Caracas)")),
              DropdownMenuItem(value: "America/Bogota", child: Text("Colombia (Bogotá)")),
            ],
            onChanged: (val) => settings.setTimezone(val!),
          ),
          const SizedBox(height: 30),
          const Text("SISTEMA Y MONEDA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: settings.currency,
            decoration: const InputDecoration(labelText: "Moneda de Finanzas", border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: "USD", child: Text("Dólar (USD)")),
              DropdownMenuItem(value: "COP", child: Text("Peso Colombiano (COP)")),
              DropdownMenuItem(value: "VES", child: Text("Bolívar (VES)")),
            ],
            onChanged: (val) => settings.setCurrency(val!),
          ),
          const SizedBox(height: 20),
          const Text("TAMAÑO DE LETRA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ChoiceChip(
                label: const Text("Pequeña"),
                selected: settings.fontSizeFactor == 0.8,
                onSelected: (val) => settings.setFontSize(0.8),
              ),
              ChoiceChip(
                label: const Text("Mediana"),
                selected: settings.fontSizeFactor == 1.0,
                onSelected: (val) => settings.setFontSize(1.0),
              ),
              ChoiceChip(
                label: const Text("Grande"),
                selected: settings.fontSizeFactor == 1.2,
                onSelected: (val) => settings.setFontSize(1.2),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Text("NOTIFICACIONES", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: settings.soundType,
            decoration: const InputDecoration(labelText: "Sonido de Alerta", border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: "standard", child: Text("Estándar (Suave)")),
              DropdownMenuItem(value: "alarm", child: Text("Alarma (Fuerte)")),
            ],
            onChanged: (val) => settings.setSoundType(val!),
          ),
          const SizedBox(height: 30),
          const Text("APARIENCIA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          SwitchListTile(
            title: const Text("Modo Noche"),
            value: settings.isDarkMode,
            onChanged: (val) => settings.toggleTheme(),
          ),
          const SizedBox(height: 30),
          ListTile(
            leading: const Icon(Icons.play_circle_outline, color: Colors.purple),
            title: const Text("Ver Tutorial"),
            onTap: () async {
              await settings.resetTutorial();
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.blue),
            title: const Text("Créditos"),
            onTap: () {
              showDialog(context: context, builder: (context) => const AlertDialog(title: Text("Créditos"), content: Text("Christian Romero (ChrizDev)")));
            },
          ),
          const SizedBox(height: 50),
          Center(
            child: TextButton(
              onPressed: () {
                final pass = TextEditingController();
                showDialog(context: context, builder: (context) => AlertDialog(
                  title: const Text("Dev Mode"),
                  content: TextField(controller: pass, obscureText: true),
                  actions: [TextButton(onPressed: () {
                    if (pass.text == "ChrizDev3008") {
                      Navigator.pop(context);
                      DBHelper().clearAllData();
                    }
                  }, child: const Text("BORRAR TODO"))]
                ));
              },
              child: const Text("SUPER DESARROLLADOR", style: TextStyle(fontSize: 10, color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }
}
