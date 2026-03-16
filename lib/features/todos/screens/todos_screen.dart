import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/page_switcher/providers/managed_pages_provider.dart';
import '../../../shared/widgets/widgets.dart';
import '../models/todo_models.dart';
import '../providers/todos_provider.dart';

class TodosScreen extends StatefulWidget {
  const TodosScreen({super.key});

  @override
  State<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final pageId = context.read<ManagedPagesProvider>().activePageId;
    if (pageId != null) {
      context.read<TodosProvider>().fetchTodos(pageId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TodosProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('To-Do Tasks')),
      body: Column(
        children: [
          // Status filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'pending', label: Text('Pending')),
                ButtonSegment(value: 'done', label: Text('Done')),
                ButtonSegment(value: 'dismissed', label: Text('Dismissed')),
              ],
              selected: {provider.statusFilter},
              onSelectionChanged: (s) {
                provider.setStatusFilter(s.first);
                _load();
              },
            ),
          ),
          // Category filters
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _categories.map((cat) {
                final isSelected = provider.categoryFilter == cat.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat.label),
                    selected: isSelected,
                    onSelected: (_) => provider.setCategoryFilter(cat.value),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // List
          Expanded(
            child: provider.isLoading && provider.items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: QpLoading(itemCount: 6),
                  )
                : provider.error != null && provider.items.isEmpty
                    ? ErrorState(message: provider.error!, onRetry: _load)
                    : provider.items.isEmpty
                        ? const EmptyState(
                            icon: Icons.checklist,
                            title: 'No tasks found',
                          )
                        : RefreshIndicator(
                            onRefresh: () async => _load(),
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: provider.items.length,
                              itemBuilder: (_, i) {
                                final todo = provider.items[i];
                                return Dismissible(
                                  key: ValueKey(todo.id),
                                  background: Container(
                                    color: Colors.green,
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.only(left: 16),
                                    child: const Icon(Icons.check,
                                        color: Colors.white),
                                  ),
                                  secondaryBackground: Container(
                                    color: Colors.grey,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 16),
                                    child: const Icon(Icons.close,
                                        color: Colors.white),
                                  ),
                                  confirmDismiss: (dir) async {
                                    final pageId = context
                                        .read<ManagedPagesProvider>()
                                        .activePageId;
                                    if (pageId == null) return false;
                                    final newStatus =
                                        dir == DismissDirection.startToEnd
                                            ? 'done'
                                            : 'dismissed';
                                    return await context
                                        .read<TodosProvider>()
                                        .updateTodoStatus(
                                            pageId, todo.id, newStatus);
                                  },
                                  child: _TodoTile(todo: todo),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  static const _categories = [
    _Category('All', 'all'),
    _Category('Messages', 'message'),
    _Category('Comments', 'comment'),
    _Category('Setup', 'setup'),
    _Category('Content', 'content'),
    _Category('Ads', 'ad'),
  ];
}

class _Category {
  final String label;
  final String value;
  const _Category(this.label, this.value);
}

class _TodoTile extends StatelessWidget {
  final TodoItem todo;
  const _TodoTile({required this.todo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _PriorityDot(priority: todo.priority),
        title: Text(
          todo.title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            decoration:
                todo.status == 'done' ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: todo.description.isNotEmpty
            ? Text(todo.description,
                maxLines: 2, overflow: TextOverflow.ellipsis)
            : null,
        trailing: _CategoryChip(category: todo.category),
        onTap: () {
          // TODO: Navigate to linked action
        },
      ),
    );
  }
}

class _PriorityDot extends StatelessWidget {
  final String priority;
  const _PriorityDot({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      'high' => Colors.red,
      'medium' => Colors.amber,
      _ => Colors.grey,
    };
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;
  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category,
        style: TextStyle(fontSize: 11, color: AppColors.primary),
      ),
    );
  }
}
