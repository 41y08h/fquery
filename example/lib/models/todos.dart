// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Todo {
  final int id;
  final String text;
  final bool isDone;
  Todo({
    required this.id,
    required this.text,
    this.isDone = false,
  });

  Todo copyWith({
    int? id,
    String? text,
    bool? isDone,
  }) {
    return Todo(
      id: id ?? this.id,
      text: text ?? this.text,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'text': text,
      'isDone': isDone,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as int,
      text: map['text'] as String,
      isDone: map['isDone'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory Todo.fromJson(String source) =>
      Todo.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'Todo(id: $id, text: $text, isDone: $isDone)';

  @override
  bool operator ==(covariant Todo other) {
    if (identical(this, other)) return true;

    return other.id == id && other.text == text && other.isDone == isDone;
  }

  @override
  int get hashCode => id.hashCode ^ text.hashCode ^ isDone.hashCode;
}

// Mock server class
class MockServer {
  static Future<void> delay({int seconds = 3}) async {
    await Future.delayed(Duration(seconds: seconds));
  }
}

class TodosAPI {
  final List<Todo> _todos = [
    Todo(id: 1, text: 'Finish homework'),
    Todo(id: 2, text: 'Buy groceries'),
    Todo(id: 3, text: 'Call mom'),
    Todo(id: 4, text: 'Go for a run'),
    Todo(id: 5, text: 'Read a book'),
    Todo(id: 6, text: 'Write an article'),
    Todo(id: 7, text: 'Cook dinner'),
    Todo(id: 8, text: 'Attend meeting'),
    Todo(id: 9, text: 'Practice guitar'),
    Todo(id: 10, text: 'Plan vacation'),
  ];
  int idCount = 10; // Initialized with the last ID used

  // Private static instance variable
  static TodosAPI? _instance;

  // Private constructor
  TodosAPI._();

  // Factory method to provide access to the singleton instance
  factory TodosAPI.getInstance() {
    // If an instance doesn't exist, create one; otherwise, return the existing instance
    _instance ??= TodosAPI._();
    return _instance!;
  }

  Future<Todo> add(String text) async {
    final todo = Todo(id: ++idCount, text: text);
    _todos.add(todo);
    await MockServer.delay();
    return todo;
  }

  Future<List<Todo>> getAll() async {
    await MockServer.delay();
    return List<Todo>.from(_todos);
  }

  Future<Todo> edit(int id, String newText) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      _todos[index] = _todos[index].copyWith(text: newText);
      await MockServer.delay();
      return _todos[index];
    } else {
      await MockServer.delay();
      throw Exception("Todo not found");
    }
  }

  Future<Todo> mark(int id, bool mark) async {
    final index = _todos.indexWhere((todo) => todo.id == id);

    if (index != -1) {
      _todos[index] = _todos[index].copyWith(isDone: mark);
      await MockServer.delay();
      return _todos[index];
    } else {
      await MockServer.delay();
      throw Exception("Todo not found");
    }
  }

  Future<void> delete(int id) async {
    _todos.removeWhere((todo) => todo.id == id);
    await MockServer.delay();
  }
}
