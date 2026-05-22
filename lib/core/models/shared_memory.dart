// SharedMemory model representing a memory or milestone shared between mother and partner.
// Stored in Firestore under `shared_memories` collection.

import 'package:cloud_firestore/cloud_firestore.dart';

class SharedMemory {
  final String id;
  final String type; // e.g., 'milestone', 'photo', 'note'
  final String content; // text content or URL for photo
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  SharedMemory({
    required this.id,
    required this.type,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  factory SharedMemory.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SharedMemory(
      id: doc.id,
      type: data['type'] as String,
      content: data['content'] as String,
      createdAt: data['createdAt'] as Timestamp,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'content': content,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}
