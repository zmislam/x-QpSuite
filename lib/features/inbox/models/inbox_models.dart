class InboxThread {
  final String id;
  final InboxContact contact;
  final InboxMessage? lastMessage;
  final DateTime updatedAt;
  final bool isRead;

  InboxThread({
    required this.id,
    required this.contact,
    this.lastMessage,
    required this.updatedAt,
    this.isRead = true,
  });

  factory InboxThread.fromJson(Map<String, dynamic> json) {
    return InboxThread(
      id: json['_id'] ?? '',
      contact: InboxContact.fromJson(json['contact'] ?? {}),
      lastMessage: json['lastMessage'] != null
          ? InboxMessage.fromJson(json['lastMessage'])
          : null,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      isRead: json['isRead'] ?? true,
    );
  }
}

class InboxContact {
  final String id;
  final String firstName;
  final String lastName;
  final String? username;
  final String? profilePicture;

  InboxContact({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.username,
    this.profilePicture,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory InboxContact.fromJson(Map<String, dynamic> json) {
    return InboxContact(
      id: json['_id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      username: json['username'],
      profilePicture: json['profile_picture'],
    );
  }
}

class InboxMessage {
  final String id;
  final String content;
  final String? senderId;
  final MessageSender? sender;
  final DateTime createdAt;

  InboxMessage({
    required this.id,
    required this.content,
    this.senderId,
    this.sender,
    required this.createdAt,
  });

  factory InboxMessage.fromJson(Map<String, dynamic> json) {
    return InboxMessage(
      id: json['_id'] ?? '',
      content: json['content'] ?? '',
      senderId: json['sender'] is String ? json['sender'] : null,
      sender: json['sender'] is Map<String, dynamic>
          ? MessageSender.fromJson(json['sender'])
          : null,
      createdAt:
          DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class MessageSender {
  final String firstName;
  final String lastName;
  final String? profilePicture;

  MessageSender({
    required this.firstName,
    required this.lastName,
    this.profilePicture,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory MessageSender.fromJson(Map<String, dynamic> json) {
    return MessageSender(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      profilePicture: json['profile_picture'],
    );
  }
}
