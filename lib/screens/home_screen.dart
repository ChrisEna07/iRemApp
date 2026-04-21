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
  
  // Para el tutorial animado
  int _tutorialStep = 0;
  bool _showingTutorial = false;

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
      String today = DateFormat('EEEE', 'es_VE').format(DateTime.now());
      today = today[0].toUpperCase() + today.substring(1);
      final data = await _dbHelper.getTasksByDay(today);
      setState(() => _tasks = data);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void _navigateToTool(String name, Widget target) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => LoadingScreen(toolName: name, targetScreen: target),
    ));
  }

  void _showTaskDetail(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(task.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (task.imagePath != null) 
              ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(task.imagePath!), height: 180, fit: BoxFit.cover)),
            const SizedBox(height: 10),
            Text("Hora: ${DateFormat('hh:mm a').format(task.dateTime)}"),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialOverlay() {
    final steps = [
      {"text": "Aquí puedes ver tus versículos diarios para inspirarte.", "align": Alignment.center},
      {"text": "Toca aquí para abrir el menú de herramientas (Calendario, Finanzas, Calculadora).", "align": Alignment.topLeft},
      {"text": "Usa la tuerca para cambiar tu nombre, el sonido y el tamaño de letra.", "align": Alignment.topRight},
      {"text": "¡Este es el botón más importante! Úsalo para crear tus recordatorios.", "align": Alignment.bottomRight},
      {"text": "Aquí verás tus tareas de hoy. Puedes marcarlas como hechas tocando el cuadrito.", "align": Alignment.bottomCenter},
    ];

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_tutorialStep < steps.length - 1) {
            _tutorialStep++;
          } else {
            _showingTutorial = false;
            _tutorialStep = 0;
            context.read<AppSettings>().completeTutorial();
          }
        });
      },
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Stack(
          children: [
            // Animación de círculo resaltador (Simulado con un círculo animado)
            if (_tutorialStep == 1) Positioned(top: 30, left: 10, child: _buildRipple()),
            if (_tutorialStep == 2) Positioned(top: 30, right: 10, child: _buildRipple()),
            if (_tutorialStep == 3) Positioned(bottom: 20, right: 20, child: _buildRipple()),
            
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      steps[_tutorialStep]["text"] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    const Text("(Toca la pantalla para continuar)", style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRipple() {
    return TweenAnimationBuilder(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 1),
      builder: (context, double value, child) {
        return Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blue.withOpacity(1 - value), width: 4 * value),
          ),
        );
      },
      onEnd: () => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<AppSettings>();

    // Verificar si se solicitó ver el tutorial desde ajustes
    if (!settings.hasSeenTutorial && !_showingTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _showingTutorial = true);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("iRememberApp"),
        leading: Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer())),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()))),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: theme.colorScheme.primary),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.apps, color: Colors.white, size: 40),
                  const SizedBox(height: 10),
                  Text("Ecosistema de ${settings.userName}", style: const TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            ),
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
              const SliverPadding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), sliver: SliverToBoxAdapter(child: Text("Hoy", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
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
                            subtitle: Text(DateFormat('hh:mm a').format(task.dateTime)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue), onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => AddTaskScreen(taskToEdit: task))); _loadTasks(); }),
                                IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red), onPressed: () async {
                                  bool? confirm = await showDialog(context: context, builder: (context) => AlertDialog(title: const Text("¿Eliminar?"), content: const Text("¿Estás seguro?"), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("NO")), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("SÍ"))]));
                                  if (confirm == true) { await _dbHelper.deleteTask(task.id!); _loadTasks(); }
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
}