import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  bool _isDarkMode = false;
  String _userName = "Usuario";
  bool _hasSeenTutorial = false;
  String _timezone = "America/Caracas";
  
  double _rateVES = 44.50;
  double _rateCOP = 3600.0;
  String _soundType = "standard";

  // --- NUEVAS PREFERENCIAS ---
  String _currency = "USD"; // USD, COP, VES
  double _fontSizeFactor = 1.0; // 0.8 (Pequeña), 1.0 (Mediana), 1.2 (Grande)

  bool get isDarkMode => _isDarkMode;
  String get userName => _userName;
  bool get hasSeenTutorial => _hasSeenTutorial;
  String get timezone => _timezone;
  double get rateVES => _rateVES;
  double get rateCOP => _rateCOP;
  String get soundType => _soundType;
  String get currency => _currency;
  double get fontSizeFactor => _fontSizeFactor;

  AppSettings() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _userName = prefs.getString('userName') ?? "Usuario";
    _hasSeenTutorial = prefs.getBool('hasSeenTutorial') ?? false;
    _timezone = prefs.getString('timezone') ?? "America/Caracas";
    _rateVES = prefs.getDouble('rateVES') ?? 44.50;
    _rateCOP = prefs.getDouble('rateCOP') ?? 3600.0;
    _soundType = prefs.getString('soundType') ?? "standard";
    _currency = prefs.getString('currency') ?? "USD";
    _fontSizeFactor = prefs.getDouble('fontSizeFactor') ?? 1.0;
    notifyListeners();
  }

  Future<void> setCurrency(String cur) async {
    _currency = cur;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', cur);
    notifyListeners();
  }

  Future<void> setFontSize(double factor) async {
    _fontSizeFactor = factor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSizeFactor', factor);
    notifyListeners();
  }

  Future<void> setSoundType(String type) async {
    _soundType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('soundType', _soundType);
    notifyListeners();
  }

  Future<void> updateRates(double ves, double cop) async {
    _rateVES = ves;
    _rateCOP = cop;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('rateVES', _rateVES);
    await prefs.setDouble('rateCOP', _rateCOP);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> setUserName(String name) async {
    _userName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _userName);
    notifyListeners();
  }

  Future<void> setTimezone(String tz) async {
    _timezone = tz;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('timezone', _timezone);
    notifyListeners();
  }

  Future<void> completeTutorial() async {
    _hasSeenTutorial = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenTutorial', true);
    notifyListeners();
  }

  Future<void> resetTutorial() async {
    _hasSeenTutorial = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenTutorial', false);
    notifyListeners();
  }
}
