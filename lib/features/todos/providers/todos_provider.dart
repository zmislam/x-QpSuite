import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/todo_models.dart';

class TodosProvider extends ChangeNotifier {
  final ApiService _api;

  List<TodoItem> _items = [];
  bool _isLoading = false;
  String? _error;
  String _statusFilter = 'pending';
  String _categoryFilter = 'all';

  TodosProvider({required ApiService api}) : _api = api;

  List<TodoItem> get items {
    if (_categoryFilter == 'all') return _items;
    return _items.where((t) => t.category == _categoryFilter).toList();
  }

  List<TodoItem> get allItems => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get statusFilter => _statusFilter;
  String get categoryFilter => _categoryFilter;

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setCategoryFilter(String cat) {
    _categoryFilter = cat;
    notifyListeners();
  }

  Future<void> fetchTodos(String pageId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.get(
        ApiConstants.todos(pageId),
        queryParameters: {'status': _statusFilter},
      );
      if (res.data['success'] == true) {
        final list = res.data['data'] as List? ?? [];
        _items = list.map((e) => TodoItem.fromJson(e)).toList();
        // Sort by priority: high → medium → low
        _items.sort((a, b) => _priorityRank(a.priority)
            .compareTo(_priorityRank(b.priority)));
      } else {
        _error = res.data['message'] ?? 'Failed to load todos';
      }
    } catch (e) {
      _error = 'Could not load todos.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateTodoStatus(
      String pageId, String todoId, String newStatus) async {
    try {
      final res = await _api.patch(
        ApiConstants.todoById(pageId, todoId),
        data: {'status': newStatus},
      );
      if (res.data['success'] == true) {
        final idx = _items.indexWhere((t) => t.id == todoId);
        if (idx >= 0) {
          _items = List.from(_items)
            ..[idx] = _items[idx].copyWith(status: newStatus);
          notifyListeners();
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  static int _priorityRank(String p) {
    switch (p) {
      case 'high':
        return 0;
      case 'medium':
        return 1;
      default:
        return 2;
    }
  }
}
