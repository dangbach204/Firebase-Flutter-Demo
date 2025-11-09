import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart' as fb_storage;
import 'firebase_client.dart';

class StorageFile {
  final String $id;
  final String? name;
  final int? sizeOriginal;
  final String? $createdAt;

  StorageFile({
    required this.$id,
    this.name,
    this.sizeOriginal,
    this.$createdAt,
  });
}

class StorageService {
  final fb_storage.FirebaseStorage _storage = FirebaseService.storage;

  Future<String?> uploadFile(
    String fileName,
    Uint8List fileBytes, {
    String? uploaderId,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final fileId = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final ref = _storage.ref().child(fileId);

      debugPrint('Uploading file: $fileName as $fileId');
      final uploadTask = ref.putData(
        fileBytes,
        fb_storage.SettableMetadata(
          customMetadata: {if (uploaderId != null) 'uploaderId': uploaderId},
        ),
      );

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((taskSnapshot) {
          final progress =
              taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
          onProgress(progress);
        });
      }

      await uploadTask.whenComplete(() {});

      debugPrint('File uploaded successfully: $fileId');
      return fileId;
    } on fb_storage.FirebaseException catch (e) {
      debugPrint('FirebaseStorageException uploading file: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error uploading file: $e');
      rethrow;
    }
  }

  Future<String> getDownloadURL(String fileId) async {
    try {
      final url = await _storage.ref().child(fileId).getDownloadURL();
      debugPrint('Download URL: $url');
      return url;
    } on fb_storage.FirebaseException catch (e) {
      debugPrint('Error getting download URL: ${e.message}');
      rethrow;
    }
  }

  String getFileDownload(String fileId) {
    return _storage.ref().child(fileId).getDownloadURL().toString();
  }

  Future<Uint8List> downloadFileBytes(String fileId) async {
    try {
      final data = await _storage
          .ref()
          .child(fileId)
          .getData(10 * 1024 * 1024); // up to 10MB
      if (data == null) throw 'No data returned from storage';
      debugPrint('File downloaded: ${data.length} bytes');
      return data;
    } on fb_storage.FirebaseException catch (e) {
      debugPrint('Error downloading file: ${e.message}');
      rethrow;
    }
  }

  Future<List<dynamic>> listFiles() async {
    try {
      final root = _storage.ref();
      final result = await root.listAll();
      final List<dynamic> files = [];

      for (final item in result.items) {
        try {
          final meta = await item.getMetadata();
          files.add(
            StorageFile(
              $id: item.fullPath,
              name: item.name,
              sizeOriginal: meta.size,
              $createdAt: meta.timeCreated?.toIso8601String(),
            ),
          );
        } catch (e) {
          // If metadata fetching fails, still include basic info
          files.add(StorageFile($id: item.fullPath, name: item.name));
        }
      }

      debugPrint('Files listed: ${files.length} files found');
      return files;
    } on fb_storage.FirebaseException catch (e) {
      debugPrint('FirebaseStorageException listing files: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error listing files: $e');
      rethrow;
    }
  }

  Future<void> deleteFile(String fileId) async {
    try {
      await _storage.ref().child(fileId).delete();
      debugPrint('File deleted: $fileId');
    } on fb_storage.FirebaseException catch (e) {
      debugPrint('Error deleting file: ${e.message}');
      rethrow;
    }
  }
}
