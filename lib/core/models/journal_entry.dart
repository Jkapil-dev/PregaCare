import 'package:flutter/material.dart';

/// Production-grade model representing a single pregnancy journal entry.
class JournalEntry {
  final String id;
  final String date; // "yyyy-MM-dd" to easily prevent duplicates for a day
  String title;
  String content;
  String mood; // "😊 Happy", "😌 Calm", "😢 Emotional", "😰 Anxious", "🤍 Excited", "😴 Tired"
  bool isBookmarked;
  final DateTime createdAt;
  DateTime updatedAt;

  JournalEntry({
    required this.id,
    required this.date,
    this.title = '',
    required this.content,
    required this.mood,
    this.isBookmarked = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Formatted date string for UI display (e.g. "21 May 2026")
  String get displayDate {
    try {
      final parsed = DateTime.parse(date);
      return "${parsed.day} ${_getMonthName(parsed.month)} ${parsed.year}";
    } catch (_) {
      return date;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'title': title,
        'content': content,
        'mood': mood,
        'isBookmarked': isBookmarked,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Deserialize from JSON
  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String? ?? UniqueKey().toString(),
      date: json['date'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      mood: json['mood'] as String? ?? '😊 Happy',
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      createdAt: json.containsKey('createdAt')
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json.containsKey('updatedAt')
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  /// Copy with modifications
  JournalEntry copyWith({
    String? title,
    String? content,
    String? mood,
    bool? isBookmarked,
    DateTime? updatedAt,
  }) {
    return JournalEntry(
      id: id,
      date: date,
      title: title ?? this.title,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
