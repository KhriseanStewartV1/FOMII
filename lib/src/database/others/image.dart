import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';

// Add this method to handle compression
Future<XFile?> compressImage(
  File file,
  int minWidth,
  int minHeight,
  int quality,
  String stringPath,
) async {
  final initFile = await file.length();
  print("Initial Size $initFile");
  // final dir = await Directory.systemTemp.createTemp();
  final targetPath = stringPath;
  // '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

  final result = await FlutterImageCompress.compressAndGetFile(
    file.absolute.path,
    targetPath,
    quality: quality,
    minWidth: minWidth,
    minHeight: minHeight,
  );

  if (result != null) {
    final sizeInBytes = await result.length(); // Get size in bytes
    print('Compressed image size: $sizeInBytes bytes');
  } else {
    print('Compression failed');
  }

  return result;
}

File toFile(XFile xfile) {
  return File(xfile.path);
}
