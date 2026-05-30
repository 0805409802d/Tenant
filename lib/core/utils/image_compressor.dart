import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageCompressor {
  /// Comprime una imagen desde bytes a un máximo de 720x720 pixeles y 50% de calidad.
  /// Ideal para subir a Supabase Storage con `uploadBinary`
  static Future<Uint8List?> compressImageBytes(Uint8List bytes) async {
    final result = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 480,
      minHeight: 480,
      quality: 35,
      format: CompressFormat.jpeg,
    );
    return result;
  }
}
