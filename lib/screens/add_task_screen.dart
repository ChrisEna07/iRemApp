import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../database/db_helper.dart';
import '../models/task_model.dart';
import '../services/notification_service.dart';
import '../providers/app_settings.dart';
import '../main.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? taskToEdit;
  final DateTime? initialDate;

  const AddTaskScreen({super.key, this.taskToEdit, this.initialDate});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _anticipationDays = 0;
  File? _selectedImage;
  final DBHelper _dbHelper = DBHelper();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) _selectedDate = widget.initialDate!;
    if (widget.taskToEdit != null) {
      _titleController.text = widget.taskToEdit!.title;
      _selectedDate = widget.taskToEdit!.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(widget.taskToEdit!.dateTime);
      _anticipationDays = widget.taskToEdit!.anticipationDays;
      if (widget.taskToEdit!.imagePath != null) _selectedImage = File(widget.taskToEdit!.imagePath!);
    }
  }

  void _showCentralFeedback(String message, IconData icon, Color color, {VoidCallback? onFinished}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
            if (onFinished != null) onFinished();
          }
        });
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

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (image != null) setState(() => _selectedImage = File(image.path));
  }

  Future<void> _saveTask() async {
    final settings = context.read<AppSettings>();
    if (_titleController.text.isEmpty) return;
    if (kIsWeb) return;

    final DateTime scheduledDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute);
    String dayName = DateFormat('EEEE', 'es_VE').format(scheduledDateTime);
    dayName = dayName[0].toUpperCase() + dayName.substring(1);

    try {
      final task = Task(
        id: widget.taskToEdit?.id,
        title: _titleController.text,
        description: "Recordatorio de iRememberApp",
        dayOfWeek: dayName,
        dateTime: scheduledDateTime,
        isDone: widget.taskToEdit?.isDone ?? false,
        imagePath: _selectedImage?.path,
        anticipationDays: _anticipationDays,
      );

      int id;
      if (widget.taskToEdit != null) {
        await _dbHelper.updateTask(task);
        id = task.id!;
        // Programamos ANTES del feedback para asegurar que el servicio responda
        await NotificationService.scheduleNotification(id, "¡${settings.userName}, es hora!", _titleController.text, scheduledDateTime, settings.timezone, sound: settings.soundType, anticipationDays: _anticipationDays);
        _showCentralFeedback("¡Actualizado!", Icons.check_circle, Colors.blue, onFinished: () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        id = await _dbHelper.insertTask(task);
        await NotificationService.scheduleNotification(id, "¡${settings.userName}, es hora!", _titleController.text, scheduledDateTime, settings.timezone, sound: settings.soundType, anticipationDays: _anticipationDays);
        _showCentralFeedback("¡Guardado!", Icons.check_circle, Colors.green, onFinished: () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) { debugPrint("Error: $e"); }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<AppSettings>();
    final isDark = settings.isDarkMode;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(widget.taskToEdit != null ? "Editar" : "Nuevo")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("¿Qué recordar, ${settings.userName}?", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: _titleController, decoration: InputDecoration(hintText: "Ej: Tomar medicina...", filled: true, fillColor: isDark ? Colors.grey[900] : Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 32),
            Text("Anticipación", style: TextStyle(fontWeight: FontWeight.bold, color: theme.hintColor)),
            DropdownButton<int>(value: _anticipationDays, items: List.generate(8, (index) => DropdownMenuItem(value: index, child: Text(index == 0 ? "El mismo día" : "$index días antes"))), onChanged: (val) => setState(() => _anticipationDays = val!)),
            const SizedBox(height: 32),
            Text("Foto", style: TextStyle(fontWeight: FontWeight.bold, color: theme.hintColor)),
            const SizedBox(height: 12),
            GestureDetector(onTap: _pickImage, child: Container(height: 120, width: double.infinity, decoration: BoxDecoration(color: isDark ? Colors.grey[900] : Colors.grey[100], borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)), child: _selectedImage != null ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(_selectedImage!, fit: BoxFit.cover)) : const Center(child: Icon(Icons.camera_alt)))),
            const SizedBox(height: 32),
            Text("Fecha y Hora", style: TextStyle(fontWeight: FontWeight.bold, color: theme.hintColor)),
            const SizedBox(height: 12),
            ListTile(leading: const Icon(Icons.calendar_today), title: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)), onTap: () async { DateTime? picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2030)); if (picked != null) setState(() => _selectedDate = picked); }),
            ListTile(leading: const Icon(Icons.access_time), title: Text(_selectedTime.format(context)), onTap: () async { TimeOfDay? picked = await showTimePicker(context: context, initialTime: _selectedTime); if (picked != null) setState(() => _selectedTime = picked); }),
            const SizedBox(height: 48),
            SizedBox(width: double.infinity, height: 60, child: ElevatedButton(onPressed: _saveTask, child: const Text("GUARDAR", style: TextStyle(fontWeight: FontWeight.bold)))),
          ],
        ),
      ),
    );
  }
}