import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../database/db_helper.dart';
import '../../models/task_model.dart';
import '../add_task_screen.dart';
import '../../providers/app_settings.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final DBHelper _dbHelper = DBHelper();
  List<Task> _dayTasks = [];
  Set<String> _daysWithTasks = {}; 

  // Listas de festivos por país
  final Map<String, Map<DateTime, String>> _countryHolidays = {
    "Venezuela": {
      DateTime(2026, 1, 1): "Año Nuevo",
      DateTime(2026, 2, 16): "Carnaval",
      DateTime(2026, 2, 17): "Carnaval",
      DateTime(2026, 4, 2): "Jueves Santo",
      DateTime(2026, 4, 3): "Viernes Santo",
      DateTime(2026, 4, 19): "Declaración de Independencia",
      DateTime(2026, 5, 1): "Día del Trabajador",
      DateTime(2026, 6, 24): "Batalla de Carabobo",
      DateTime(2026, 7, 5): "Día de la Independencia",
      DateTime(2026, 7, 24): "Natalicio de Simón Bolívar",
      DateTime(2026, 10, 12): "Resistencia Indígena",
      DateTime(2026, 12, 24): "Nochebuena",
      DateTime(2026, 12, 25): "Navidad",
      DateTime(2026, 12, 31): "Fin de Año",
    },
    "Colombia": {
      DateTime(2026, 1, 1): "Año Nuevo",
      DateTime(2026, 1, 12): "Día de los Reyes Magos",
      DateTime(2026, 3, 23): "Día de San José",
      DateTime(2026, 4, 2): "Jueves Santo",
      DateTime(2026, 4, 3): "Viernes Santo",
      DateTime(2026, 5, 1): "Día del Trabajo",
      DateTime(2026, 5, 25): "Ascensión del Señor",
      DateTime(2026, 6, 15): "Corpus Christi",
      DateTime(2026, 6, 22): "Sagrado Corazón",
      DateTime(2026, 6, 29): "San Pedro y San Pablo",
      DateTime(2026, 7, 20): "Día de la Independencia",
      DateTime(2026, 8, 7): "Batalla de Boyacá",
      DateTime(2026, 8, 17): "Asunción de la Virgen",
      DateTime(2026, 10, 12): "Día de la Raza",
      DateTime(2026, 11, 2): "Día de Todos los Santos",
      DateTime(2026, 11, 16): "Independencia de Cartagena",
      DateTime(2026, 12, 8): "Inmaculada Concepción",
      DateTime(2026, 12, 25): "Navidad",
    }
  };

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAllTaskDays();
    _loadDayTasks(_selectedDay!);
  }

  Future<void> _loadAllTaskDays() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> res = await db.query('tasks');
    final Set<String> markedDays = {};
    for (var r in res) {
      markedDays.add(r['dateTime'].substring(0, 10));
    }
    setState(() => _daysWithTasks = markedDays);
  }

  Future<void> _loadDayTasks(DateTime date) async {
    final tasks = await _dbHelper.getTasksByDate(date);
    setState(() => _dayTasks = tasks);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final holidays = _countryHolidays[settings.country] ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text("Calendario Personal")),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            locale: 'es_ES',
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _loadDayTasks(selectedDay);
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                final String dateKey = date.toIso8601String().substring(0, 10);
                final List<Widget> markers = [];

                // Marcador para festivos (Rojo)
                DateTime holidayKey = DateTime(date.year, date.month, date.day);
                if (holidays.containsKey(holidayKey)) {
                  markers.add(Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)));
                }

                // Marcador para tareas personales (Azul)
                if (_daysWithTasks.contains(dateKey)) {
                  markers.add(Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)));
                }

                if (markers.isEmpty) return null;

                return Positioned(
                  bottom: 1,
                  child: Row(mainAxisSize: MainAxisSize.min, children: markers.map((m) => Padding(padding: const EdgeInsets.symmetric(horizontal: 1), child: m)).toList()),
                );
              },
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info de Festivo si existe
                if (holidays.containsKey(DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)))
                  Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.redAccent)),
                    child: Row(children: [const Icon(Icons.flag, color: Colors.redAccent), const SizedBox(width: 10), Expanded(child: Text("¡Día Especial!: ${holidays[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)]}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)))]),
                  ),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Recordatorios del día", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.blue),
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (context) => AddTaskScreen(initialDate: _selectedDay)));
                        _loadAllTaskDays();
                        _loadDayTasks(_selectedDay!);
                      },
                    ),
                  ],
                ),
                if (_dayTasks.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No hay tareas guardadas hoy")))
                else ..._dayTasks.map((task) => ListTile(
                  leading: const Icon(Icons.bookmark, color: Colors.blue),
                  title: Text(task.title),
                  subtitle: Text(DateFormat('hh:mm a').format(task.dateTime)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (context) => AddTaskScreen(taskToEdit: task)));
                        _loadAllTaskDays();
                        _loadDayTasks(_selectedDay!);
                      }),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () async {
                        await _dbHelper.deleteTask(task.id!);
                        _loadAllTaskDays();
                        _loadDayTasks(_selectedDay!);
                      }),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
