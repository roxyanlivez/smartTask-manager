import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(const TaskApp());
}

class TaskApp extends StatelessWidget {
  const TaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartTask Manager',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TaskHomePage(),
    );
  }
}

class TaskHomePage extends StatefulWidget {
  const TaskHomePage({super.key});

  @override
  _TaskHomePageState createState() => _TaskHomePageState();
}

class _TaskHomePageState extends State<TaskHomePage> {
  late Database db;
  List<Map> tasks = [];

  @override
  void initState() {
    super.initState();
    initDb();
  }

  Future<void> initDb() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'tasks.db');

    db = await openDatabase(path, version: 1, onCreate: (db, version) {
      return db.execute(
        "CREATE TABLE tasks(id INTEGER PRIMARY KEY, title TEXT, done INTEGER)",
      );
    });

    loadTasks();
  }

  Future<void> loadTasks() async {
    final List<Map> list = await db.query('tasks');
    setState(() => tasks = list);
  }

  Future<void> addTask(String title) async {
    await db.insert('tasks', {'title': title, 'done': 0});
    loadTasks();
  }

  Future<void> toggleTask(int id, int done) async {
    await db.update('tasks', {'done': done == 0 ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
    loadTasks();
  }

  Future<void> deleteTask(int id) async {
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController controller = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('SmartTask Manager')),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return ListTile(
            title: Text(task['title']),
            leading: Checkbox(
              value: task['done'] == 1,
              onChanged: (_) => toggleTask(task['id'], task['done']),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => deleteTask(task['id']),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Add Task'),
                content: TextField(controller: controller),
                actions: [
                  TextButton(
                    child: const Text('Add'),
                    onPressed: () {
                      addTask(controller.text);
                      Navigator.pop(context);
                    },
                  )
                ],
              );
            },
          );
        },
      ),
    );
  }
}

