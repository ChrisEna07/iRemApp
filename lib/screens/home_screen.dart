import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../database/db_helper.dart';
import '../models/task_model.dart';
import '../providers/app_settings.dart';
import 'add_task_screen.dart';
import 'settings_screen.dart';
import 'tools/grocery_list_screen.dart';
import 'tools/calculator_screen.dart';
import 'tools/currency_converter_screen.dart';
import 'tools/calendar_screen.dart';
import 'tools/finance_screen.dart';
import 'tools/loading_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> versiculos = [
    "«Todo lo puedo en Cristo que me fortalece.» - Filipenses 4:13",
    "«Jehová es mi pastor; nada me faltará.» - Salmo 23:1",
    "«No temas, porque yo estoy contigo.» - Isaías 41:10",
    "«Venid a mí todos los que estáis cansados y cargados, y yo os haré descansar.» - Mateo 11:28",
  ];

  late PageController _pageController;
  int _currentPage = 0;
  List<Task> _tasks = [];
  final DBHelper _dbHelper = DBHelper();
  int _tutorialStep = 0;
  bool _showingTutorial = false;
  
  // Filtro: 'Hoy', 'Mes', 'Año'
  String _activeFilter = 'Hoy';

  @override
  void initState() {
    super.initState();
    _currentPage = Random().nextInt(versiculos.length);
    _pageController = PageController(initialPage: _currentPage);
    _loadTasks();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFirstRun());
    Timer.periodic(const Duration(seconds: 15), (Timer timer) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % versiculos.length;
        _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 1200), curve: Curves.easeInOut);
      }
    });
  }

  Future<void> _checkFirstRun() async {
    final settings = context.read<AppSettings>();
    if (!settings.hasSeenTutorial) {
      await _requestInitialPermissions();
      setState(() => _showingTutorial = true);
    }
  }

  Future<void> _requestInitialPermissions() async {
    await Permission.notification.request();
    await Permission.camera.request();
  }

  Future<void> _loadTasks() async {
    if (kIsWeb) return;
    try {
      final db = await _dbHelper.database;
      List<Map<String, dynamic>> res;
      DateTime now = DateTime.now();
      
      if (_activeFilter == 'Hoy') {
        String todayStr = now.toIso8601String().substring(0, 10);
        res = await db.query('tasks', where: "dateTime LIKE ?", whereArgs: ['$todayStr%']);
      } else if (_activeFilter == 'Mes') {
        String monthStr = now.toIso8601String().substring(0, 7);
        res = await db.query('tasks', where: "dateTime LIKE ?", whereArgs: ['$monthStr%']);
      } else {
        // Año
        String yearStr = now.toIso8601String().substring(0, 4);
        res = await db.query('tasks', where: "dateTime LIKE ?", whereArgs: ['$yearStr%']);
      }
      
      setState(() => _tasks = res.map((e) => Task.fromMap(e)).toList());
    } catch (e) { debugPrint("Error: $e"); }
  }

  void _showCentralFeedback(String message, IconData icon, Color color) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (Navigator.canPop(context)) Navigator.pop(context);
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

  void _navigateToTool(String name, Widget target) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => LoadingScreen(toolName: name, targetScreen: target)));
  }

  void _showTaskDetail(Task task) {
    showDialog(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: Text(task.title), content: Column(mainAxisSize: MainAxisSize.min, children: [if (task.imagePath != null) ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(task.imagePath!), height: 180, fit: BoxFit.cover)), const SizedBox(height: 10), Text("Fecha: ${DateFormat('dd/MM/yyyy - hh:mm a').format(task.dateTime)}")] )));
  }

  Widget _buildTutorialOverlay() {
    final steps = [
      {"text": "Aquí puedes ver tus versículos diarios para inspirarte.", "align": Alignment.center},
      {"text": "Toca aquí (Menú) para abrir el Calendario, Finanzas y más.", "align": Alignment.topLeft},
      {"text": "Aquí (Configuración) puedes cambiar tu nombre, sonidos y letras.", "align": Alignment.topRight},
      {"text": "¡Usa este botón (+) para crear tus recordatorios!", "align": Alignment.bottomRight},
      {"text": "Aquí verás tus tareas. ¡Usa los filtros para ver las del Mes o Año!", "align": Alignment.bottomCenter},
    ];

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_tutorialStep < steps.length - 1) { _tutorialStep++; } 
          else { _showingTutorial = false; _tutorialStep = 0; context.read<AppSettings>().completeTutorial(); }
        });
      },
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: Stack(
          children: [
            if (_tutorialStep == 1) _buildArrow(top: 40, left: 20, angle: -pi / 4),
            if (_tutorialStep == 2) _buildArrow(top: 40, right: 20, angle: pi / 4),
            if (_tutorialStep == 3) _buildArrow(bottom: 70, right: 30, angle: 3 * pi / 4),
            if (_tutorialStep == 4) _buildArrow(bottom: 150, left: MediaQuery.of(context).size.width / 2 - 25, angle: pi),
            Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 40.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Text(steps[_tutorialStep]["text"] as String, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, decoration: TextDecoration.none, fontFamily: 'Roboto'))), const SizedBox(height: 20), const Text("(Toca para continuar)", style: TextStyle(color: Colors.white70, fontSize: 14, decoration: TextDecoration.none))]))),
          ],
        ),
      ),
    );
  }

  Widget _buildArrow({double? top, double? left, double? right, double? bottom, required double angle}) {
    return Positioned(top: top, left: left, right: right, bottom: bottom, child: TweenAnimationBuilder(tween: Tween(begin: 0.0, end: 10.0), duration: const Duration(milliseconds: 500), builder: (context, double value, child) { return Transform.translate(offset: Offset(0, value), child: Transform.rotate(angle: angle, child: const Icon(Icons.arrow_upward, color: Colors.yellowAccent, size: 50))); }, onEnd: () => setState(() {})));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<AppSettings>();
    if (!settings.hasSeenTutorial && !_showingTutorial) { WidgetsBinding.instance.addPostFrameCallback((_) { setState(() => _showingTutorial = true); }); }

    return Scaffold(
      appBar: AppBar(
        title: const Text("iRememberApp"),
        leading: Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer())),
        actions: [IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())))],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(decoration: BoxDecoration(color: theme.colorScheme.primary), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.apps, color: Colors.white, size: 40), const SizedBox(height: 10), Text("Ecosistema de ${settings.userName}", style: const TextStyle(color: Colors.white, fontSize: 18))])),
            ListTile(leading: const Icon(Icons.account_balance_wallet, color: Colors.purple), title: const Text("Control Financiero"), onTap: () => _navigateToTool("Finanzas", const FinanceScreen())),
            ListTile(leading: const Icon(Icons.calendar_month, color: Colors.red), title: const Text("Calendario"), onTap: () => _navigateToTool("Calendario", const CalendarScreen())),
            ListTile(leading: const Icon(Icons.shopping_cart, color: Colors.orange), title: const Text("Lista de Compras"), onTap: () => _navigateToTool("Lista de Compras", const GroceryListScreen())),
            ListTile(leading: const Icon(Icons.calculate, color: Colors.blue), title: const Text("Calculadora"), onTap: () => _navigateToTool("Calculadora", const CalculatorScreen())),
            ListTile(leading: const Icon(Icons.currency_exchange, color: Colors.green), title: const Text("Conversor"), onTap: () => _navigateToTool("Conversor", const CurrencyConverterScreen())),
          ],
        ),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20.0), child: Text("¡Hola, ${settings.userName}! ❤️", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)))),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 160,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: versiculos.length,
                    itemBuilder: (context, index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                      child: Center(child: Text(versiculos[index], textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic))),
                    ),
                  ),
                ),
              ),
              // CHIPS DE FILTRADO
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      _buildFilterChip('Hoy'),
                      const SizedBox(width: 10),
                      _buildFilterChip('Mes'),
                      const SizedBox(width: 10),
                      _buildFilterChip('Año'),
                      const Spacer(),
                      Text("${_tasks.length} recordatorios", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              _tasks.isEmpty
                  ? const SliverFillRemaining(hasScrollBody: false, child: Center(child: Text("Sin tareas pendientes")))
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final task = _tasks[index];
                          return ListTile(
                            onTap: () => _showTaskDetail(task),
                            leading: Checkbox(value: task.isDone, onChanged: (v) async { await _dbHelper.updateTaskStatus(task.id!, v!); _loadTasks(); }),
                            title: Text(task.title, style: TextStyle(decoration: task.isDone ? TextDecoration.lineThrough : null)),
                            subtitle: Text(_activeFilter == 'Hoy' ? DateFormat('hh:mm a').format(task.dateTime) : DateFormat('dd/MM - hh:mm a').format(task.dateTime)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue), onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => AddTaskScreen(taskToEdit: task))); _loadTasks(); }),
                                IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red), onPressed: () async {
                                  bool? confirm = await showDialog(context: context, builder: (context) => AlertDialog(title: const Text("¿Eliminar?"), content: const Text("¿Estás seguro?"), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("NO")), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("SÍ"))]));
                                  if (confirm == true) { await _dbHelper.deleteTask(task.id!); _loadTasks(); _showCentralFeedback("¡Eliminado!", Icons.delete, Colors.red); }
                                }),
                              ],
                            ),
                          );
                        },
                        childCount: _tasks.length,
                      ),
                    ),
            ],
          ),
          if (_showingTutorial) _buildTutorialOverlay(),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTaskScreen())); _loadTasks(); }, child: const Icon(Icons.add)),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _activeFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() => _activeFilter = label);
          _loadTasks();
        }
      },
    );
  }
}