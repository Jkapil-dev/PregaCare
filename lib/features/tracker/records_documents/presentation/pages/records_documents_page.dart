import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maatricare/core/theme/colors.dart';
import 'package:maatricare/core/theme/typography.dart';
import 'package:maatricare/core/theme/theme.dart';
import 'package:maatricare/core/widgets/common_widgets.dart';

class RecordsDocumentsPage extends StatefulWidget {
  const RecordsDocumentsPage({super.key});

  @override
  State<RecordsDocumentsPage> createState() => _RecordsDocumentsPageState();
}

class _RecordsDocumentsPageState extends State<RecordsDocumentsPage> {
  // Document Categories
  final List<_DocItem> _ultrasounds = [
    _DocItem('Anomaly Ultrasound Scan', '24 May 2026', Icons.photo_size_select_actual_rounded),
    _DocItem('First Trimester Viability Scan', '10 Jan 2026', Icons.photo_size_select_actual_rounded),
  ];

  final List<_DocItem> _labReports = [
    _DocItem('Complete Blood Count (CBC)', '18 Apr 2026', Icons.description_rounded),
    _DocItem('Glucose Tolerance Test (GTT)', '14 Apr 2026', Icons.description_rounded),
  ];

  final List<_DocItem> _prescriptions = [
    _DocItem('Dr. Sharma OBGYN Prescription', '18 Apr 2026', Icons.receipt_long_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      appBar: AppBar(
        title: const Text('Records & Documents'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MaatriTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Health Folders', style: MaatriTypography.headlineMedium),
                    const SizedBox(height: 2),
                    Text('Preserves medical summaries & scans securely', style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate)),
                  ],
                ),
                GestureDetector(
                  onTap: _showDocOptions,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: MaatriColors.teal.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.add_photo_alternate_rounded, color: MaatriColors.teal, size: 24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MaatriTheme.spacingLg),

            // ── CATEGORIES ──
            _buildCategorySection('Ultrasounds & Scans', _ultrasounds, MaatriColors.coral),
            const SizedBox(height: MaatriTheme.spacingMd),

            _buildCategorySection('Lab Test Reports', _labReports, MaatriColors.teal),
            const SizedBox(height: MaatriTheme.spacingMd),

            _buildCategorySection('Prescriptions & Notes', _prescriptions, MaatriColors.goldenAmber),
            const SizedBox(height: MaatriTheme.spacingXxl),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(String title, List<_DocItem> list, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder_open_rounded, color: color, size: 22),
              const SizedBox(width: 8),
              Text(title, style: MaatriTypography.titleMedium),
              const Spacer(),
              Text('${list.length} files', style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.slate)),
            ],
          ),
          const SizedBox(height: 12),
          ...list.map((doc) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: MaatriColors.cloudGray, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Icon(doc.icon, color: color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc.name, style: MaatriTypography.titleSmall),
                        Text(doc.date, style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.slate)),
                      ],
                    ),
                  ),
                  const Icon(Icons.open_in_new_rounded, color: MaatriColors.mediumGray, size: 16),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  void _showDocOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: MaatriColors.pureWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add New Document', style: MaatriTypography.headlineSmall),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: MaatriColors.coralLight.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.camera_alt_rounded, color: MaatriColors.coral),
              ),
              title: const Text('Take Camera Photo'),
              subtitle: const Text('Instantly crop and scan paper records'),
              onTap: () async {
                Navigator.pop(ctx);
                final img = await ImagePicker().pickImage(source: ImageSource.camera);
                if (img != null) {
                  setState(() {
                    _ultrasounds.insert(0, _DocItem(img.name, 'Today', Icons.photo_size_select_actual_rounded));
                  });
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: MaatriColors.tealLight.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.upload_file_rounded, color: MaatriColors.teal),
              ),
              title: const Text('Upload PDF/File'),
              subtitle: const Text('Select reports from device storage'),
              onTap: () async {
                Navigator.pop(ctx);
                final img = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (img != null) {
                  setState(() {
                    _labReports.insert(0, _DocItem(img.name, 'Today', Icons.description_rounded));
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DocItem {
  final String name;
  final String date;
  final IconData icon;

  _DocItem(this.name, this.date, this.icon);
}
