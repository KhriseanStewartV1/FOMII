import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

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

Future<Uint8List?> getVideoThumbnail(String path) async {
  return await VideoThumbnail.thumbnailData(
    video: path,
    imageFormat: ImageFormat.JPEG,
    maxWidth: 100,
    quality: 100,
  );
}

// Add this method to handle compression
Future<File?> compressVideo(File file, String stringPath) async {
  final initFile = await file.length();
  print("Initial Size: $initFile bytes");

  try {
    MediaInfo? mediaInfo = await VideoCompress.compressVideo(
      file.path,
      quality: VideoQuality.MediumQuality,
      deleteOrigin: false,
    );

    if (mediaInfo == null || mediaInfo.file == null) {
      print("❌ Compression failed");
      return null;
    }

    final sizeInBytes = mediaInfo.filesize ?? 0;
    print('✅ Compressed video size: $sizeInBytes bytes');

    return mediaInfo.file;
  } catch (e) {
    print("⚠️ Compression error: $e");
    return null;
  }
}

File toFile(XFile xfile) {
  return File(xfile.path);
}
