import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:maatricare/core/theme/colors.dart';
import 'package:maatricare/core/theme/typography.dart';
import 'package:maatricare/core/theme/theme.dart';
import 'package:maatricare/core/widgets/common_widgets.dart';
import 'package:maatricare/core/models/medical_record.dart';
import 'package:maatricare/core/services/medical_record_storage_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'document_preview_page.dart';

class RecordsDocumentsPage extends StatefulWidget {
  const RecordsDocumentsPage({super.key});
  @override
  State<RecordsDocumentsPage> createState() => _RecordsDocumentsPageState();
}

class _RecordsDocumentsPageState extends State<RecordsDocumentsPage> {
  final MedicalRecordStorageService _storageService = MedicalRecordStorageService();
  final ImagePicker _imagePicker = ImagePicker();
  List<MedicalRecord> _records = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final list = await _storageService.loadRecords();
    setState(() { _records = list; _isLoading = false; });
  }

  List<MedicalRecord> get _filteredRecords {
    if (_selectedCategory == 'All') return _records;
    return _records.where((r) => r.category == _selectedCategory).toList();
  }

  Map<String, int> get _categoryCounts {
    final counts = <String, int>{'All': _records.length};
    for (final cat in MedicalRecord.allCategories) {
      counts[cat] = _records.where((r) => r.category == cat).length;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRecords;
    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      appBar: AppBar(
        title: const Text('Records & Documents'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(MaatriTheme.spacingMd),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Medical Records Vault', style: MaatriTypography.headlineMedium),
                const SizedBox(height: 4),
                Text('Securely store ultrasounds, prescriptions & lab reports', style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate)),
                const SizedBox(height: MaatriTheme.spacingLg),

                // Summary bar
                _buildSummaryBar(),
                const SizedBox(height: MaatriTheme.spacingMd),

                // Category filter chips
                _buildCategoryFilter(),
                const SizedBox(height: MaatriTheme.spacingMd),

                // Upload button
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_photo_alternate_rounded, size: 20),
                    label: const Text('Upload New Record'),
                    style: ElevatedButton.styleFrom(backgroundColor: MaatriColors.coral),
                    onPressed: _showUploadSheet,
                  ),
                ),
                const SizedBox(height: MaatriTheme.spacingMd),

                // Records list
                if (filtered.isEmpty)
                  Center(child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(children: [
                      Icon(Icons.folder_open_rounded, size: 48, color: MaatriColors.mediumGray.withValues(alpha: 0.5)),
                      const SizedBox(height: 8),
                      Text(_selectedCategory == 'All' ? 'No records uploaded yet.' : 'No $_selectedCategory records.', style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate)),
                    ]),
                  ))
                else
                  ...filtered.map((rec) => _buildRecordCard(rec)),
                const SizedBox(height: MaatriTheme.spacingXxl),
              ]),
            ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: MaatriColors.tealGradient, borderRadius: BorderRadius.circular(16), boxShadow: MaatriTheme.shadowMd),
      child: Row(children: [
        const Icon(Icons.folder_special_rounded, color: Colors.white, size: 28),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Total Records', style: MaatriTypography.titleMedium.copyWith(color: Colors.white)),
          Text('${_records.length} files stored securely', style: MaatriTypography.bodySmall.copyWith(color: Colors.white70)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
          child: Text('${_records.length}', style: MaatriTypography.displaySmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  Widget _buildCategoryFilter() {
    final counts = _categoryCounts;
    final categories = ['All', ...MedicalRecord.allCategories];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: categories.map((cat) {
        final active = _selectedCategory == cat;
        final count = counts[cat] ?? 0;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text('$cat ($count)'),
            selected: active,
            selectedColor: MaatriColors.coralLight.withValues(alpha: 0.4),
            checkmarkColor: MaatriColors.coral,
            onSelected: (_) => setState(() => _selectedCategory = cat),
          ),
        );
      }).toList()),
    );
  }

  Widget _buildRecordCard(MedicalRecord rec) {
    final catColor = MedicalRecord.getCategoryColor(rec.category);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Thumbnail / Icon
            GestureDetector(
              onTap: () => _previewRecord(rec),
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: catColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: _buildThumbnail(rec, catColor),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(rec.fileName, style: MaatriTypography.titleSmall.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                GestureDetector(onTap: () => _previewRecord(rec), child: const Icon(Icons.visibility_outlined, color: MaatriColors.teal, size: 20)),
                const SizedBox(width: 10),
                GestureDetector(onTap: () => _confirmDelete(rec.id), child: const Icon(Icons.delete_outline_rounded, color: MaatriColors.danger, size: 20)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: catColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(rec.category, style: TextStyle(color: catColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Text(rec.displayDate, style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.slate)),
              ]),
              if (rec.notes.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(rec.notes, style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate, fontStyle: FontStyle.italic, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ])),
          ]),
        ]),
      ),
    );
  }

  Widget _buildThumbnail(MedicalRecord rec, Color catColor) {
    if (rec.isImage && rec.filePath.isNotEmpty) {
      if (kIsWeb) {
        try {
          final bytes = base64Decode(rec.filePath);
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(bytes, width: 56, height: 56, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(child: Icon(rec.fileIcon, color: catColor, size: 28))),
          );
        } catch (e) {
          return Center(child: Icon(rec.fileIcon, color: catColor, size: 28));
        }
      } else {
        final file = File(rec.filePath);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(file, width: 56, height: 56, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Center(child: Icon(rec.fileIcon, color: catColor, size: 28))),
        );
      }
    }
    return Center(child: Icon(rec.fileIcon, color: catColor, size: 28));
  }

  // ── UPLOAD SHEET ──
  void _showUploadSheet() {
    showModalBottomSheet(
      context: context, backgroundColor: MaatriColors.pureWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Upload Medical Record', style: MaatriTypography.headlineSmall),
          const SizedBox(height: 16),
          _uploadOption(Icons.camera_alt_rounded, MaatriColors.coral, 'Take Photo', 'Capture prescription or report using camera', () async {
            Navigator.pop(ctx);
            await _pickFromCamera();
          }),
          const Divider(),
          _uploadOption(Icons.photo_library_rounded, MaatriColors.teal, 'Choose from Gallery', 'Select existing images from your device', () async {
            Navigator.pop(ctx);
            await _pickFromGallery();
          }),
          const Divider(),
          _uploadOption(Icons.picture_as_pdf_rounded, MaatriColors.goldenAmber, 'Upload PDF / Document', 'Select a PDF report from device storage', () async {
            Navigator.pop(ctx);
            await _pickPdfFile();
          }),
        ]),
      ),
    );
  }

  Widget _uploadOption(IconData icon, Color color, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      onTap: onTap,
    );
  }

  // ── PERMISSIONS HELPER ──
  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) return true;
    final status = await Permission.camera.status;
    if (status.isGranted) return true;

    final result = await Permission.camera.request();
    if (result.isGranted) {
      return true;
    } else if (result.isPermanentlyDenied) {
      _showPermissionSettingsDialog('Camera');
    } else {
      _showError('Camera permission is required to capture photos.');
    }
    return false;
  }

  Future<bool> _requestStoragePermission() async {
    if (kIsWeb) return true;
    
    // For Android 13+ (SDK 33+), READ_MEDIA_IMAGES is used instead of STORAGE.
    // In permission_handler, checking Permission.photos requests READ_MEDIA_IMAGES.
    // On older versions, Permission.storage requests READ/WRITE_EXTERNAL_STORAGE.
    PermissionStatus status;
    if (Platform.isAndroid) {
      final photosStatus = await Permission.photos.status;
      if (photosStatus.isGranted) return true;
      
      // Request photos permission first
      status = await Permission.photos.request();
      
      // If photos is restricted/denied/not supported (e.g. pre-Android 13), fallback to storage
      if (status.isDenied || status.isRestricted) {
        status = await Permission.storage.request();
      }
    } else {
      status = await Permission.storage.request();
    }

    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      _showPermissionSettingsDialog('Storage/Photos');
    } else {
      _showError('Storage permission is required to select files.');
    }
    return false;
  }

  void _showPermissionSettingsDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$permissionName Permission Required'),
        content: Text('MaatriCare needs $permissionName permission to select and save medical records. Please enable it in the app settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: MaatriColors.coral),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // Helper to validate allowed file extensions
  bool _isValidFileType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return ext == 'pdf' || ext == 'jpg' || ext == 'jpeg' || ext == 'png';
  }

  // ── CAMERA ──
  Future<void> _pickFromCamera() async {
    final hasPermission = await _requestCameraPermission();
    if (!hasPermission) return;

    try {
      final image = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (image == null) return; // Cancelled
      
      if (!_isValidFileType(image.name)) {
        _showError('Unsupported file type. Only PDF, JPG, and PNG are allowed.');
        return;
      }

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        await _showCategorySaveDialog(fileName: image.name, fileType: 'image', fileBytes: bytes);
      } else {
        await _showCategorySaveDialog(fileName: image.name, fileType: 'image', filePath: image.path);
      }
    } catch (e) {
      _showError('Camera not available or cancelled: $e');
    }
  }

  // ── GALLERY ──
  Future<void> _pickFromGallery() async {
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) return;

    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image == null) return; // Cancelled

      if (!_isValidFileType(image.name)) {
        _showError('Unsupported file type. Only PDF, JPG, and PNG are allowed.');
        return;
      }

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        await _showCategorySaveDialog(fileName: image.name, fileType: 'image', fileBytes: bytes);
      } else {
        await _showCategorySaveDialog(fileName: image.name, fileType: 'image', filePath: image.path);
      }
    } catch (e) {
      _showError('Gallery selection failed or cancelled: $e');
    }
  }

  // ── PDF/FILE ──
  Future<void> _pickPdfFile() async {
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result == null || result.files.isEmpty) return; // Cancelled

      final file = result.files.first;
      if (!_isValidFileType(file.name)) {
        _showError('Unsupported file type. Only PDF, JPG, and PNG are allowed.');
        return;
      }

      final fileType = file.name.split('.').last.toLowerCase() == 'pdf' ? 'pdf' : 'image';

      if (kIsWeb) {
        final bytes = file.bytes;
        if (bytes == null) {
          _showError('Could not retrieve file bytes. Please try again.');
          return;
        }
        await _showCategorySaveDialog(fileName: file.name, fileType: fileType, fileBytes: bytes);
      } else {
        final path = file.path;
        if (path == null) {
          _showError('Could not retrieve file path. Please try again.');
          return;
        }
        await _showCategorySaveDialog(fileName: file.name, fileType: fileType, filePath: path);
      }
    } catch (e) {
      _showError('File picker error: $e');
    }
  }

  // ── CATEGORY + NOTES DIALOG ──
  Future<void> _showCategorySaveDialog({
    required String fileName,
    required String fileType,
    String? filePath,
    Uint8List? fileBytes,
  }) async {
    String selectedCategory = 'Other';
    final notesCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: MaatriColors.pureWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Save Medical Record', style: MaatriTypography.headlineSmall),
                const SizedBox(height: 6),
                Text(fileName, style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 16),

                // Preview thumbnail for images
                if (fileType == 'image') ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? (fileBytes != null
                            ? Image.memory(
                                fileBytes,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 100,
                                  color: MaatriColors.cloudGray,
                                  child: const Center(child: Icon(Icons.broken_image_rounded, size: 40, color: MaatriColors.mediumGray)),
                                ),
                              )
                            : const SizedBox())
                        : (filePath != null
                            ? Image.file(
                                File(filePath),
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 100,
                                  color: MaatriColors.cloudGray,
                                  child: const Center(child: Icon(Icons.broken_image_rounded, size: 40, color: MaatriColors.mediumGray)),
                                ),
                              )
                            : const SizedBox()),
                  ),
                  const SizedBox(height: 16),
                ] else if (fileType == 'pdf') ...[
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: MaatriColors.coralLight.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.picture_as_pdf_rounded, size: 40, color: MaatriColors.coral),
                        SizedBox(height: 8),
                        Text('PDF Document', style: TextStyle(fontWeight: FontWeight.bold, color: MaatriColors.coral)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Text('Record Category', style: MaatriTypography.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: MedicalRecord.allCategories.map((cat) =>
                    ChoiceChip(
                      label: Text(cat),
                      selected: selectedCategory == cat,
                      selectedColor: MedicalRecord.getCategoryColor(cat).withValues(alpha: 0.3),
                      onSelected: (_) => setS(() => selectedCategory = cat),
                    ),
                  ).toList(),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Notes (optional)',
                    prefixIcon: Icon(Icons.description_outlined, color: MaatriColors.slate),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        String recordFilePath = '';
                        if (kIsWeb) {
                          if (fileBytes != null) {
                            recordFilePath = base64Encode(fileBytes);
                          }
                        } else {
                          if (filePath != null) {
                            recordFilePath = await _storageService.saveFileLocally(filePath, fileName);
                          }
                        }

                        final record = MedicalRecord(
                          id: UniqueKey().toString(),
                          fileName: fileName,
                          fileType: fileType,
                          category: selectedCategory,
                          uploadDate: DateTime.now(),
                          filePath: recordFilePath,
                          notes: notesCtrl.text.trim(),
                        );
                        await _storageService.saveRecord(record);
                        if (mounted) {
                          Navigator.pop(ctx);
                          _loadRecords();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Medical record saved! ✓'), backgroundColor: MaatriColors.success),
                          );
                        }
                      } catch (e) {
                        _showError('Failed to save record: $e');
                      }
                    },
                    child: const Text('Save Record'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── FILE PREVIEW ──
  void _previewRecord(MedicalRecord rec) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentPreviewPage(record: rec),
      ),
    );
  }

  // ── DELETE ──
  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Record?'),
        content: const Text('This file will be permanently removed from your device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _storageService.deleteRecord(id);
              _loadRecords();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Record deleted.'), backgroundColor: MaatriColors.charcoal, behavior: SnackBarBehavior.floating),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: MaatriColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: MaatriColors.danger),
    );
  }
}
