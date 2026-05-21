import 'dart:typed_data';
import 'dart:html' as html;

void openPdfBytesInNewTab(Uint8List bytes) {
  try {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
  } catch (e) {
    // Fallback/log
  }
}
