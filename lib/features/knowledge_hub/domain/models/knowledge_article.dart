import 'package:cloud_firestore/cloud_firestore.dart';

class KnowledgeArticle {
  final String id;
  final String title;
  final String description;
  final String category;
  final String trimester;
  final String content;
  final String imageUrl;
  final List<String> tags;
  final int readTime;
  final DateTime createdAt;
  final bool featured;
  final bool weeklyRecommended;
  final String articleType;
  final String wellnessPriority;

  KnowledgeArticle({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.trimester,
    required this.content,
    required this.imageUrl,
    required this.tags,
    required this.readTime,
    required this.createdAt,
    required this.featured,
    required this.weeklyRecommended,
    required this.articleType,
    required this.wellnessPriority,
  });

  factory KnowledgeArticle.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return KnowledgeArticle(
      id: doc.id,
      title: data['title'] as String? ?? 'Untitled Article',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? 'General',
      trimester: data['trimester'] as String? ?? 'General',
      content: data['content'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      tags: (data['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      readTime: data['readTime'] as int? ?? 5,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      featured: data['featured'] as bool? ?? false,
      weeklyRecommended: data['weeklyRecommended'] as bool? ?? false,
      articleType: data['articleType'] as String? ?? 'article',
      wellnessPriority: data['wellnessPriority'] as String? ?? 'normal',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'trimester': trimester,
      'content': content,
      'imageUrl': imageUrl,
      'tags': tags,
      'readTime': readTime,
      'createdAt': Timestamp.fromDate(createdAt),
      'featured': featured,
      'weeklyRecommended': weeklyRecommended,
      'articleType': articleType,
      'wellnessPriority': wellnessPriority,
    };
  }
}
