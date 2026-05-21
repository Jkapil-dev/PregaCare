import 'dart:typed_data';
import 'web_pdf_helper_stub.dart'
    if (dart.library.js_util) 'web_pdf_helper_web.dart'
    if (dart.library.html) 'web_pdf_helper_web.dart';

void openPdfInNewTab(Uint8List bytes) {
  openPdfBytesInNewTab(bytes);
}
