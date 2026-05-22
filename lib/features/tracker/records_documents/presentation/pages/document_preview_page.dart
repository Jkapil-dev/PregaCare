import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:maatricare/core/theme/colors.dart';
import 'package:maatricare/core/theme/typography.dart';
import 'package:maatricare/core/models/medical_record.dart';
import 'package:maatricare/features/tracker/records_documents/utils/web_pdf_helper.dart';

class DocumentPreviewPage extends StatefulWidget {
  final MedicalRecord record;

  const DocumentPreviewPage({
    super.key,
    required this.record,
  });

  @override
  State<DocumentPreviewPage> createState() => _DocumentPreviewPageState();
}

class _DocumentPreviewPageState extends State<DocumentPreviewPage> {
  Uint8List? _pdfBytes;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _prepareDocument();
  }

  void _prepareDocument() {
    try {
      if (widget.record.isPdf) {
        if (kIsWeb) {
          // Decode base64 bytes for SfPdfViewer.memory
          _pdfBytes = base64Decode(widget.record.filePath);
        } else {
          // If stored on mobile, check if path exists
          if (widget.record.filePath.isNotEmpty) {
            final file = File(widget.record.filePath);
            if (!file.existsSync()) {
              // Check if original file is missing
              if (widget.record.id.startsWith('rec_')) {
                _pdfBytes = Uint8List(0); // Placeholder
              } else {
                setState(() {
                  _hasError = true;
                  _errorMessage = 'File does not exist on device storage.';
                });
              }
            }
          }
        }
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load document: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final catColor = MedicalRecord.getCategoryColor(record.category);

    return Scaffold(
      backgroundColor: MaatriColors.pureWhite,
      appBar: AppBar(
        title: Text(
          record.isPdf ? 'PDF Viewer' : 'Image Viewer',
          style: MaatriTypography.headlineSmall.copyWith(color: MaatriColors.charcoal),
        ),
        centerTitle: true,
        backgroundColor: MaatriColors.pureWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: MaatriColors.charcoal, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (record.isPdf && kIsWeb && _pdfBytes != null && _pdfBytes!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded, color: MaatriColors.teal),
              tooltip: 'Open in new tab',
              onPressed: () => openPdfInNewTab(_pdfBytes!),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Metadata header card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MaatriColors.cloudGray.withOpacity( 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: MaatriColors.lightGray.withOpacity( 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity( 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(record.fileIcon, color: catColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.fileName,
                              style: MaatriTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: catColor.withOpacity( 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    record.category,
                                    style: TextStyle(color: catColor, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  record.displayDate,
                                  style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.slate),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (record.notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Text(
                      record.notes,
                      style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),

            // Document Display Area
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity( 0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: MaatriColors.lightGray.withOpacity( 0.3)),
                ),
                clipBehavior: Clip.antiAlias,
                child: _hasError
                    ? _buildErrorWidget()
                    : (record.filePath.isEmpty || record.id.startsWith('rec_'))
                        ? _buildMockPreviewWidget()
                        : _buildMainPreview(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainPreview() {
    final record = widget.record;

    if (record.isImage) {
      return InteractiveViewer(
        maxScale: 4.0,
        child: Center(
          child: kIsWeb
              ? (() {
                  try {
                    final bytes = base64Decode(record.filePath);
                    return Image.memory(
                      bytes,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image_rounded, color: MaatriColors.mediumGray, size: 64),
                      ),
                    );
                  } catch (e) {
                    return const Center(
                      child: Icon(Icons.broken_image_rounded, color: MaatriColors.mediumGray, size: 64),
                    );
                  }
                })()
              : Image.file(
                  File(record.filePath),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_rounded, color: MaatriColors.mediumGray, size: 64),
                  ),
                ),
        ),
      );
    } else if (record.isPdf) {
      if (kIsWeb) {
        if (_pdfBytes == null) {
          return const Center(child: Text('Invalid PDF content.'));
        }
        return SfPdfViewer.memory(
          _pdfBytes!,
          onDocumentLoadFailed: (details) {
            setState(() {
              _hasError = true;
              _errorMessage = details.description;
            });
          },
        );
      } else {
        return SfPdfViewer.file(
          File(record.filePath),
          onDocumentLoadFailed: (details) {
            setState(() {
              _hasError = true;
              _errorMessage = details.description;
            });
          },
        );
      }
    } else {
      return const Center(child: Text('Unsupported file preview format.'));
    }
  }

  Widget _buildMockPreviewWidget() {
    final record = widget.record;
    final catColor = MedicalRecord.getCategoryColor(record.category);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: catColor.withOpacity( 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(record.fileIcon, size: 64, color: catColor),
            ),
            const SizedBox(height: 16),
            Text(
              'No Preview Available',
              style: MaatriTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'The original file is not accessible. Upload a new document to view its preview.',
              textAlign: TextAlign.center,
              style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: MaatriColors.danger),
            const SizedBox(height: 16),
            const Text(
              'Failed to load document',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: MaatriColors.slate),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _errorMessage = '';
                });
                _prepareDocument();
              },
              style: ElevatedButton.styleFrom(backgroundColor: MaatriColors.coral),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
