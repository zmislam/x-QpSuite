class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final String? link;
  final bool isRead;
  final NotificationActor? actor;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.link,
    required this.isRead,
    this.actor,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      link: json['link'],
      isRead: json['is_read'] ?? false,
      actor: json['actor'] != null
          ? NotificationActor.fromJson(json['actor'])
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class NotificationActor {
  final String name;
  final String? avatar;

  NotificationActor({required this.name, this.avatar});

  factory NotificationActor.fromJson(Map<String, dynamic> json) {
    return NotificationActor(
      name: json['name'] ?? '',
      avatar: json['avatar'],
    );
  }
}
