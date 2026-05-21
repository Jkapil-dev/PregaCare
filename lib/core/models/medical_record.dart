import 'package:flutter/material.dart';

/// Production-grade model for a medical record file in MaatriCare.
class MedicalRecord {
  final String id;
  String fileName;
  String fileType; // "image", "pdf", "document"
  String category; // "Ultrasounds", "Prescriptions", "Lab Reports", "Vaccinations", "Scans", "Other"
  DateTime uploadDate;
  String filePath; // Local file path (absolute)
  String notes;
  final DateTime createdAt;

  MedicalRecord({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.category,
    required this.uploadDate,
    required this.filePath,
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Check if the record is an image (for preview)
  bool get isImage => fileType == 'image';

  /// Check if the record is a PDF
  bool get isPdf => fileType == 'pdf';

  /// Icon to represent file type
  IconData get fileIcon {
    switch (fileType) {
      case 'image':
        return Icons.photo_rounded;
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  /// Color for category badge
  static Color getCategoryColor(String category) {
    switch (category) {
      case 'Ultrasounds':
        return const Color(0xFFE8736C); // coral
      case 'Lab Reports':
        return const Color(0xFF5BBFBA); // teal
      case 'Prescriptions':
        return const Color(0xFFF5C842); // golden
      case 'Vaccinations':
        return const Color(0xFF9B84D9); // lavender
      case 'Scans':
        return const Color(0xFF60A5FA); // info blue
      default:
        return const Color(0xFF9CA3AF); // slate
    }
  }

  /// Formatted date for UI display
  String get displayDate {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${uploadDate.day} ${months[uploadDate.month - 1]} ${uploadDate.year}';
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'fileType': fileType,
        'category': category,
        'uploadDate': uploadDate.toIso8601String(),
        'filePath': filePath,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Deserialize from JSON
  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      id: json['id'] as String? ?? UniqueKey().toString(),
      fileName: json['fileName'] as String? ?? 'Untitled',
      fileType: json['fileType'] as String? ?? 'document',
      category: json['category'] as String? ?? 'Other',
      uploadDate: json.containsKey('uploadDate')
          ? DateTime.parse(json['uploadDate'])
          : DateTime.now(),
      filePath: json['filePath'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      createdAt: json.containsKey('createdAt')
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  /// All supported categories
  static const List<String> allCategories = [
    'Ultrasounds',
    'Prescriptions',
    'Lab Reports',
    'Vaccinations',
    'Scans',
    'Other',
  ];
}
