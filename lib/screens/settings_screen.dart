import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings.dart';
import '../database/db_helper.dart';
import '../services/notification_service.dart';
import 'developer_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Configuración")),
      body: ListView(
        children: [
          _buildSectionTitle("Personalización"),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Nombre de Usuario"),
            subtitle: Text(settings.userName),
            onTap: () => _showEditNameDialog(context, settings),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text("Modo Oscuro"),
            value: settings.isDarkMode,
            onChanged: (val) => settings.toggleDarkMode(val),
          ),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text("Tamaño de Letra"),
            subtitle: Text(_getFontSizeLabel(settings.fontSizeFactor)),
            onTap: () => _showFontSizeDialog(context, settings),
          ),
          
          _buildSectionTitle("Preferencias"),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text("País (Festivos)"),
            subtitle: Text(settings.country),
            onTap: () => _showCountryDialog(context, settings),
          ),
          ListTile(
            leading: const Icon(Icons.monetization_on),
            title: const Text("Moneda"),
            subtitle: Text(settings.currency),
            onTap: () => _showCurrencyDialog(context, settings),
          ),
          ListTile(
            leading: const Icon(Icons.volume_up),
            title: const Text("Tipo de Sonido"),
            subtitle: Text(settings.soundType == 'alarm' ? "Alarma Fuerte" : "Estándar Suave"),
            onTap: () => _showSoundDialog(context, settings),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active, color: Colors.green),
            title: const Text("Probar Notificación", style: TextStyle(color: Colors.green)),
            subtitle: const Text("Verifica sonido y aviso central"),
            onTap: () async {
              await NotificationService.testNotification();
            },
          ),
          ListTile(
            leading: const Icon(Icons.public),
            title: const Text("Zona Horaria"),
            subtitle: Text(settings.timezone),
            onTap: () => _showTimezoneDialog(context, settings),
          ),

          _buildSectionTitle("Sistema"),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text("Ver Tutorial"),
            onTap: () async {
              await settings.resetTutorial();
              Navigator.pop(context); 
            },
          ),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings, color: Colors.blue),
            title: const Text("Modo Super Desarrollador", style: TextStyle(color: Colors.blue)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DeveloperScreen())),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text("iRememberApp v1.0.8\nDesarrollado por ChrizDev", textAlign: TextAlign.center, style: TextStyle(color: theme.hintColor, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
    );
  }

  String _getFontSizeLabel(double factor) {
    if (factor < 1.0) return "Pequeña";
    if (factor > 1.0) return "Grande";
    return "Mediana";
  }

  void _showEditNameDialog(BuildContext context, AppSettings settings) {
    final controller = TextEditingController(text: settings.userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cambiar Nombre"),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: "Nombre")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          TextButton(onPressed: () { settings.setUserName(controller.text); Navigator.pop(context); }, child: const Text("GUARDAR")),
        ],
      ),
    );
  }

  void _showFontSizeDialog(BuildContext context, AppSettings settings) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("Tamaño de Letra"),
        children: [
          _fontSizeOption(context, settings, "Pequeña", 0.8),
          _fontSizeOption(context, settings, "Mediana", 1.0),
          _fontSizeOption(context, settings, "Grande", 1.2),
        ],
      ),
    );
  }

  Widget _fontSizeOption(BuildContext context, AppSettings settings, String label, double factor) {
    return RadioListTile<double>(
      title: Text(label),
      value: factor,
      groupValue: settings.fontSizeFactor,
      onChanged: (val) { settings.setFontSize(val!); Navigator.pop(context); },
    );
  }

  void _showCountryDialog(BuildContext context, AppSettings settings) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("Seleccionar País"),
        children: [
          _countryOption(context, settings, "Colombia 🇨🇴", "Colombia"),
          _countryOption(context, settings, "Venezuela 🇻🇪", "Venezuela"),
        ],
      ),
    );
  }

  Widget _countryOption(BuildContext context, AppSettings settings, String label, String value) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: settings.country,
      onChanged: (val) { settings.setCountry(val!); Navigator.pop(context); },
    );
  }

  void _showCurrencyDialog(BuildContext context, AppSettings settings) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("Seleccionar Moneda"),
        children: [
          _currencyOption(context, settings, "Dólares (USD)", "USD"),
          _currencyOption(context, settings, "Pesos (COP)", "COP"),
          _currencyOption(context, settings, "Bolívares (VES)", "VES"),
        ],
      ),
    );
  }

  Widget _currencyOption(BuildContext context, AppSettings settings, String label, String value) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: settings.currency,
      onChanged: (val) { settings.setCurrency(val!); Navigator.pop(context); },
    );
  }

  void _showSoundDialog(BuildContext context, AppSettings settings) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("Tipo de Sonido"),
        children: [
          _soundOption(context, settings, "Estándar Suave", "standard"),
          _soundOption(context, settings, "Alarma Fuerte", "alarm"),
        ],
      ),
    );
  }

  Widget _soundOption(BuildContext context, AppSettings settings, String label, String value) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: settings.soundType,
      onChanged: (val) { settings.setSoundType(val!); Navigator.pop(context); },
    );
  }

  void _showTimezoneDialog(BuildContext context, AppSettings settings) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("Zona Horaria"),
        children: [
          _tzOption(context, settings, "Venezuela (VET)", "America/Caracas"),
          _tzOption(context, settings, "Colombia (COT)", "America/Bogota"),
        ],
      ),
    );
  }

  Widget _tzOption(BuildContext context, AppSettings settings, String label, String value) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: settings.timezone,
      onChanged: (val) { settings.setTimezone(val!); Navigator.pop(context); },
    );
  }
}
