import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  String _userName = "Usuario";
  bool _isDarkMode = false;
  double _fontSizeFactor = 1.0;
  String _currency = "USD";
  String _soundType = "standard";
  String _timezone = "America/Caracas";
  bool _isInitialized = false; // Indica si las preferencias se cargaron del disco
  String _country = "Venezuela";
  bool _hasSeenTutorial = false; 
  double _rateVES = 40.0;
  double _rateCOP = 3900.0;

  AppSettings() {
    _loadSettings();
  }

  // Getters
  String get userName => _userName;
  bool get isDarkMode => _isDarkMode;
  double get fontSizeFactor => _fontSizeFactor;
  String get currency => _currency;
  String get soundType => _soundType;
  String get timezone => _timezone;
  bool get isInitialized => _isInitialized;
  String get country => _country;
  bool get hasSeenTutorial => _hasSeenTutorial;
  double get rateVES => _rateVES;
  double get rateCOP => _rateCOP;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name') ?? "Usuario";
    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    _fontSizeFactor = prefs.getDouble('font_size_factor') ?? 1.0;
    _currency = prefs.getString('currency') ?? "USD";
    _soundType = prefs.getString('sound_type') ?? "standard";
    _timezone = prefs.getString('timezone') ?? "America/Caracas";
    _country = prefs.getString('country') ?? "Venezuela";
    _hasSeenTutorial = prefs.getBool('has_seen_tutorial') ?? false;
    _rateVES = prefs.getDouble('rate_ves') ?? 40.0;
    _rateCOP = prefs.getDouble('rate_cop') ?? 3900.0;
    _isInitialized = true; // Marcamos como cargado
    notifyListeners();
  }

  Future<void> setUserName(String name) async {
    _userName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    notifyListeners();
  }

  Future<void> updateUser(String name) async {
    await setUserName(name);
  }

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', value);
    notifyListeners();
  }

  Future<void> setFontSize(double factor) async {
    _fontSizeFactor = factor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_size_factor', factor);
    notifyListeners();
  }

  Future<void> setCurrency(String curr) async {
    _currency = curr;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', curr);
    notifyListeners();
  }

  Future<void> setSoundType(String type) async {
    _soundType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sound_type', type);
    notifyListeners();
  }

  Future<void> setTimezone(String tz) async {
    _timezone = tz;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('timezone', tz);
    notifyListeners();
  }

  Future<void> setCountry(String country) async {
    _country = country;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('country', country);
    notifyListeners();
  }

  Future<void> completeTutorial() async {
    _hasSeenTutorial = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_tutorial', true);
    notifyListeners();
  }

  Future<void> updateRates(double ves, double cop) async {
    _rateVES = ves;
    _rateCOP = cop;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('rate_ves', ves);
    await prefs.setDouble('rate_cop', cop);
    notifyListeners();
  }

  Future<void> resetTutorial() async {
    _hasSeenTutorial = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_tutorial', false);
    notifyListeners();
  }

  Future<void> completeInitialSetup(String name, String curr, String tz, bool dark, String country) async {
    _userName = name;
    _currency = curr;
    _timezone = tz;
    _isDarkMode = dark;
    _country = country;
    _hasSeenTutorial = true; 
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('currency', curr);
    await prefs.setString('timezone', tz);
    await prefs.setBool('is_dark_mode', dark);
    await prefs.setString('country', country);
    await prefs.setBool('has_seen_tutorial', true);
    notifyListeners();
  }
}
