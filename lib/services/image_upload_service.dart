import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  static const int _maxBytes = 5 * 1024 * 1024; // 5 MB
  static final _picker = ImagePicker();

  /// Opens the device gallery. Returns null if the user cancels.
  static Future<XFile?> pickFromGallery() async {
    return await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
  }

  /// Validates [image] then uploads it to [storagePath].
  /// Returns the Firebase Storage download URL.
  /// Throws an [Exception] with a user-readable message on failure.
  static Future<String> upload({
    required XFile image,
    required String storagePath,
  }) async {
    final ext = image.name.split('.').last.toLowerCase();
    if (ext != 'jpg' && ext != 'jpeg' && ext != 'png') {
      throw Exception('Only JPEG and PNG images are allowed.');
    }

    final fileSize = await File(image.path).length();
    if (fileSize > _maxBytes) {
      throw Exception('Image exceeds the 5 MB limit. Please choose a smaller file.');
    }

    final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
    final ref = FirebaseStorage.instance.ref(storagePath);
    await ref.putFile(
      File(image.path),
      SettableMetadata(contentType: contentType),
    );
    return await ref.getDownloadURL();
  }
}
