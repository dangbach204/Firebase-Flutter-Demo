import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'appwrite_client.dart';

class StorageService {
  final Storage _storage = AppwriteService.storage;
  final String _bucketId = AppwriteService.bucketId;

  Future<String?> uploadFile(
    String fileName,
    Uint8List fileBytes, {
    String? uploaderId,
    Function(int bytesTransferred, int totalBytes)? onProgress,
  }) async {
    try {
      final fileId = ID.unique();

      final inputFile = InputFile.fromBytes(
        bytes: fileBytes,
        filename: fileName,
      );

      debugPrint('Uploading to bucket: $_bucketId');
      debugPrint('File name: $fileName');
      debugPrint('File size: ${fileBytes.length} bytes');

      final totalBytes = fileBytes.length;

      // Nếu có callback, gọi nó với tiến trình ban đầu
      onProgress?.call(0, totalBytes);

      final file = await _storage.createFile(
        bucketId: _bucketId,
        fileId: fileId,
        file: inputFile,
        onProgress: onProgress != null
            ? (UploadProgress progress) {
                debugPrint(
                  'Upload progress: ${progress.chunksUploaded}/${progress.chunksTotal}',
                );
                // Tính toán bytes đã upload dựa trên chunks
                final bytesTransferred =
                    (progress.chunksUploaded *
                            totalBytes /
                            progress.chunksTotal)
                        .round();
                onProgress(bytesTransferred, totalBytes);
              }
            : null,
      );

      // Hoàn thành 100%
      onProgress?.call(totalBytes, totalBytes);

      debugPrint('File uploaded successfully: ${file.$id}');
      return file.$id;
    } on AppwriteException catch (e) {
      debugPrint('AppwriteException uploading file:');
      debugPrint('  Code: ${e.code}');
      debugPrint('  Message: ${e.message}');
      debugPrint('  Response: ${e.response}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error uploading file: $e');
      rethrow;
    }
  }

  Future<String> getDownloadURL(String fileId) async {
    try {
      final result = _storage.getFileView(bucketId: _bucketId, fileId: fileId);

      debugPrint('Download URL: $result');
      return result.toString();
    } on AppwriteException catch (e) {
      debugPrint('Error getting download URL: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error getting download URL: $e');
      rethrow;
    }
  }

  String getFileDownload(String fileId) {
    return _storage
        .getFileDownload(bucketId: _bucketId, fileId: fileId)
        .toString();
  }

  Future<Uint8List> downloadFileBytes(String fileId) async {
    try {
      final bytes = await _storage.getFileDownload(
        bucketId: _bucketId,
        fileId: fileId,
      );
      debugPrint('File downloaded: ${bytes.length} bytes');
      return bytes;
    } on AppwriteException catch (e) {
      debugPrint('Error downloading file: ${e.message}');
      rethrow;
    }
  }

  Future<List<dynamic>> listFiles() async {
    try {
      final fileList = await _storage.listFiles(bucketId: _bucketId);
      debugPrint('Files listed: ${fileList.files.length} files found');
      return fileList.files;
    } on AppwriteException catch (e) {
      debugPrint('AppwriteException listing files:');
      debugPrint('  Code: ${e.code}');
      debugPrint('  Message: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error listing files: $e');
      rethrow;
    }
  }

  Future<void> deleteFile(String fileId) async {
    try {
      await _storage.deleteFile(bucketId: _bucketId, fileId: fileId);
      debugPrint('File deleted: $fileId');
    } on AppwriteException catch (e) {
      debugPrint('Error deleting file: ${e.message}');
      rethrow;
    }
  }
}
