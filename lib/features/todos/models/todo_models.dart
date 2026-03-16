class TodoItem {
  final String id;
  final String type;
  final String category;
  final String title;
  final String description;
  final String? link;
  final String status; // pending | done | dismissed
  final String priority; // high | medium | low

  TodoItem({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.description,
    this.link,
    required this.status,
    required this.priority,
  });

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? 'auto',
      category: json['category'] ?? 'general',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      link: json['link'],
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'low',
    );
  }

  TodoItem copyWith({String? status}) {
    return TodoItem(
      id: id,
      type: type,
      category: category,
      title: title,
      description: description,
      link: link,
      status: status ?? this.status,
      priority: priority,
    );
  }
}
