// Shared Milestone model representing a pregnancy milestone shared between mother and partner.
// This model is stored in Firestore under a collection like `shared_milestones`.

import 'package:cloud_firestore/cloud_firestore.dart';

class SharedMilestone {
  final String id;
  final int week; // Pregnancy week the milestone is associated with.
  final String title;
  final String emoji;
  final bool achieved; // Whether the mother has achieved this milestone.
  final Timestamp createdAt; // Firestore server timestamp when record was created.
  final Timestamp? updatedAt; // Optional update timestamp.

  SharedMilestone({
    required this.id,
    required this.week,
    required this.title,
    required this.emoji,
    required this.achieved,
    required this.createdAt,
    this.updatedAt,
  });

  factory SharedMilestone.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SharedMilestone(
      id: doc.id,
      week: data['week'] as int,
      title: data['title'] as String,
      emoji: data['emoji'] as String,
      achieved: data['achieved'] as bool,
      createdAt: data['createdAt'] as Timestamp,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toJson() => {
        'week': week,
        'title': title,
        'emoji': emoji,
        'achieved': achieved,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}
