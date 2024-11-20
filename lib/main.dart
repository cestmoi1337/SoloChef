import 'package:flutter/material.dart';
import 'database/db_helper.dart'; // Import the DBHelper class.

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensures Flutter is ready for async operations.
  await DBHelper().database; // Initialize the SQLite database.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  String _itemName = '';
  int _quantity = 1;
  String _expirationDate = '';
  int? _editingItemId; // Tracks the ID of the item being edited

  // Opens a dialog with a form to input pantry details
  void _openAddOrEditItemDialog({Map<String, dynamic>? item}) {
    // If editing, populate form fields with item data
    if (item != null) {
      _itemName = item['name'];
      _quantity = item['quantity'];
      _expirationDate = item['expiration'];
      _editingItemId = item['id'];
    } else {
      // Reset form fields for adding a new item
      _itemName = '';
      _quantity = 1;
      _expirationDate = '';
      _editingItemId = null;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item == null ? 'Add Pantry Item' : 'Edit Pantry Item'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Item Name Input
                TextFormField(
                  initialValue: _itemName,
                  decoration: const InputDecoration(labelText: 'Item Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the item name.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _itemName = value!;
                  },
                ),
                // Quantity Input
                TextFormField(
                  initialValue: _quantity.toString(),
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || int.tryParse(value) == null) {
                      return 'Please enter a valid quantity.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _quantity = int.parse(value!);
                  },
                ),
                // Expiration Date Input
                TextFormField(
                  initialValue: _expirationDate,
                  decoration: const InputDecoration(
                      labelText: 'Expiration Date (YYYY-MM-DD)'),
                  validator: (value) {
                    if (value == null ||
                        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
                      return 'Please enter a valid date in YYYY-MM-DD format.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _expirationDate = value!;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close dialog
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _saveOrUpdatePantryItem,
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Saves a new item or updates an existing item in the database
  void _saveOrUpdatePantryItem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_editingItemId == null) {
        // Add a new item
        await DBHelper()
            .insertPantryItem(_itemName, _quantity, _expirationDate);
      } else {
        // Update an existing item
        await DBHelper().updatePantryItem(
          _editingItemId!,
          _itemName,
          _quantity,
          _expirationDate,
        );
      }

      Navigator.pop(context); // Close the dialog
      setState(() {}); // Refresh the list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: FutureBuilder(
        future: DBHelper().fetchPantryItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final items = snapshot.data as List<Map<String, dynamic>>;
            if (items.isEmpty) {
              return const Center(child: Text('No items in the pantry.'));
            }
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  title: Text(item['name']),
                  subtitle: Text(
                      'Quantity: ${item['quantity']} | Expiration: ${item['expiration']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          _openAddOrEditItemDialog(
                              item: item); // Open edit dialog
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await DBHelper().deletePantryItem(item['id']);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddOrEditItemDialog(), // Open add item dialog
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
    );
  }
}
