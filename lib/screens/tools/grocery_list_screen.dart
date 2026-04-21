import 'package:flutter/material.dart';
import '../../database/db_helper.dart'; // Corregido el path

class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({super.key});

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  final DBHelper _dbHelper = DBHelper();
  final TextEditingController _itemController = TextEditingController();
  List<Map<String, dynamic>> _groceries = [];

  @override
  void initState() {
    super.initState();
    _loadGroceries();
  }

  Future<void> _loadGroceries() async {
    final data = await _dbHelper.getGroceries();
    setState(() {
      _groceries = data;
    });
  }

  Future<void> _addItem() async {
    if (_itemController.text.isNotEmpty) {
      await _dbHelper.insertGrocery(_itemController.text);
      _itemController.clear();
      _loadGroceries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lista de Compras")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemController,
                    decoration: const InputDecoration(hintText: "Agregar artículo..."),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: _addItem),
              ],
            ),
          ),
          Expanded(
            child: _groceries.isEmpty 
              ? const Center(child: Text("La lista está vacía"))
              : ListView.builder(
                itemCount: _groceries.length,
                itemBuilder: (context, index) {
                  final item = _groceries[index];
                  return ListTile(
                    leading: Checkbox(
                      value: item['isDone'] == 1,
                      onChanged: (val) async {
                        await _dbHelper.updateGroceryStatus(item['id'], val!);
                        _loadGroceries();
                      },
                    ),
                    title: Text(
                      item['item'],
                      style: TextStyle(
                        decoration: item['isDone'] == 1 ? TextDecoration.lineThrough : null,
                        color: item['isDone'] == 1 ? Colors.grey : null,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await _dbHelper.deleteGrocery(item['id']);
                        _loadGroceries();
                      },
                    ),
                  );
                },
              ),
          ),
        ],
      ),
    );
  }
}
