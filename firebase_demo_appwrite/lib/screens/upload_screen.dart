import 'package:firebase_demo/screens/login_screen.dart';
import 'package:firebase_demo/services/auth_service.dart';
import 'package:firebase_demo/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'dart:io' show File;

class UploadScreen extends StatefulWidget {
  final bool isGuest;

  const UploadScreen({super.key, this.isGuest = false});

  @override
  UploadScreenState createState() => UploadScreenState();
}

class UploadScreenState extends State<UploadScreen> {
  // Services
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();

  // State variables
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  bool _isCancelling = false;
  double _uploadProgress = 0.0;
  String _status = 'Chưa chọn tệp...';
  List<dynamic> _uploadedFiles = [];
  bool _isLoadingFiles = false;
  String? _userId;
  String? _userName;

  // Guest mode flag
  bool get _isGuest => widget.isGuest;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _getUserId();
    await _loadFiles();
  }

  Future<void> _getUserId() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        setState(() {
          _userId = user.$id;
          _userName = _isGuest
              ? 'Guest'
              : (user.name.isNotEmpty ? user.name : 'Guest');
        });
        debugPrint('User ID: $_userId, Name: $_userName, IsGuest: $_isGuest');
      } else {
        _updateStatus('Lỗi: Chưa đăng nhập. Vui lòng khởi động lại app.');
      }
    } catch (e) {
      debugPrint('Lỗi khi lấy thông tin user: $e');
      _updateStatus('Lỗi: Không thể lấy thông tin người dùng.');
    }
  }

  String _getErrorMessage(dynamic error) {
    // Kiểm tra lỗi kết nối internet
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('socketsexception') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('no address associated')) {
      return '⚠️ Không có kết nối internet. Vui lòng kiểm tra mạng và thử lại.';
    }

    if (error is AppwriteException) {
      // Kiểm tra lỗi network trong AppwriteException
      final message = error.message?.toLowerCase() ?? '';
      if (message.contains('network') ||
          message.contains('connection') ||
          message.contains('timeout')) {
        return '⚠️ Lỗi kết nối. Vui lòng kiểm tra internet và thử lại.';
      }

      switch (error.code) {
        case 401:
          return 'Bạn không có quyền thực hiện thao tác này. Vui lòng đăng nhập lại.';
        case 403:
          return 'Bạn không có quyền truy cập. Vui lòng liên hệ quản trị viên.';
        case 404:
          return 'Không tìm thấy file hoặc bucket.';
        case 500:
          return 'Lỗi server. Vui lòng thử lại sau.';
        case 503:
          return 'Dịch vụ tạm thời không khả dụng. Vui lòng thử lại sau.';
        default:
          if (message.contains('permission')) {
            return 'Lỗi quyền hạn: ${error.message}';
          }
          if (message.contains('unauthorized')) {
            return 'Bạn không có quyền thực hiện thao tác này.';
          }
          return error.message ?? 'Đã xảy ra lỗi: ${error.code}';
      }
    }

    return error.toString();
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _updateStatus(String status) {
    setState(() => _status = status);
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      _showSnackBar('Logout failed: $e', backgroundColor: Colors.red);
    }
  }

  Future<void> _pickFile() async {
    if (_isGuest) {
      _showSnackBar(
        'Chế độ Guest không được phép upload file',
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
      debugPrint('Opening file picker...');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      debugPrint(
        'File picker result: ${result != null ? "Got result" : "Null"}',
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        debugPrint('Selected file: ${file.name}');
        debugPrint('File size: ${file.size} bytes');
        debugPrint('Has bytes: ${file.bytes != null}');
        debugPrint('Has path: ${file.path != null}');

        if (file.bytes == null && file.path != null) {
          debugPrint('Reading file from path: ${file.path}');
          final fileData = await File(file.path!).readAsBytes();
          debugPrint('Read ${fileData.length} bytes from file');

          final fileWithBytes = PlatformFile(
            name: file.name,
            size: fileData.length,
            bytes: fileData,
            path: file.path,
          );

          setState(() {
            _selectedFile = fileWithBytes;
            _status = 'Đã chọn tệp: ${file.name}';
          });
          debugPrint(
            'File selected successfully with ${fileData.length} bytes',
          );
        } else if (file.bytes != null) {
          setState(() {
            _selectedFile = file;
            _status = 'Đã chọn tệp: ${file.name}';
          });
          debugPrint(
            'File selected successfully with ${file.bytes!.length} bytes',
          );
        } else {
          _updateStatus('Không thể đọc file. Vui lòng thử lại.');
          debugPrint('ERROR: No bytes and no path available');
        }
      } else {
        _updateStatus('Không chọn tệp nào.');
        debugPrint('User cancelled file picker');
      }
    } catch (e) {
      _updateStatus('Lỗi khi chọn tệp: $e');
      debugPrint('ERROR picking file: $e');
    }
  }

  Future<void> _uploadFile() async {
    if (_isGuest) {
      _showSnackBar(
        'Chế độ Guest không được phép upload file',
        backgroundColor: Colors.orange,
      );
      return;
    }

    if (_selectedFile == null) {
      _showSnackBar('Vui lòng chọn một tệp trước!');
      return;
    }

    if (_userId == null) {
      await _getUserId();
      if (_userId == null) {
        _showSnackBar('Lỗi: Không tìm thấy ID người dùng. Vui lòng thử lại.');
        return;
      }
    }

    final fileBytes = _selectedFile!.bytes;
    if (fileBytes == null) {
      _updateStatus('Lỗi: Không thể đọc file.');
      return;
    }

    setState(() {
      _isUploading = true;
      _isCancelling = false;
      _uploadProgress = 0.0;
      _status = 'Đang upload... 0%';
    });

    try {
      final fileId = await _storageService.uploadFile(
        _selectedFile!.name,
        fileBytes,
        uploaderId: _userId,
        onProgress: (bytesTransferred, totalBytes) {
          // Nếu đang cancel thì không cập nhật UI nữa
          if (_isCancelling || !mounted) return;

          final progress = bytesTransferred / totalBytes;
          setState(() {
            _uploadProgress = progress;
            _status = 'Đang upload... ${(progress * 100).toStringAsFixed(0)}%';
          });
          debugPrint(
            'Upload progress: $bytesTransferred/$totalBytes bytes (${(progress * 100).toStringAsFixed(1)}%)',
          );
        },
      );

      // Nếu đã cancel thì không xử lý kết quả
      if (_isCancelling) {
        _updateStatus('Đã hủy upload');
        _showSnackBar('Đã hủy upload', backgroundColor: Colors.orange);
        return;
      }

      if (fileId != null) {
        final downloadUrl = await _storageService.getDownloadURL(fileId);
        debugPrint('File ID: $fileId\nDownload URL: $downloadUrl');

        _updateStatus('Upload thành công!');
        _showSnackBar(
          'Upload thành công! File ID: $fileId',
          backgroundColor: Colors.green,
        );
        await _loadFiles();
      } else {
        _updateStatus('Upload thất bại: Không nhận được file ID');
      }
    } catch (e) {
      if (_isCancelling) {
        _updateStatus('Đã hủy upload');
        return;
      }

      final errorMessage = _getErrorMessage(e);
      _updateStatus('Upload thất bại: $errorMessage');
      _showSnackBar(errorMessage, backgroundColor: Colors.red);
    } finally {
      setState(() {
        _isUploading = false;
        _isCancelling = false;
        if (_uploadProgress < 1.0) _uploadProgress = 0.0;
      });
    }
  }

  void _cancelUpload() {
    if (!_isUploading) return;

    setState(() {
      _isCancelling = true;
      _status = 'Đang hủy upload...';
    });

    debugPrint('User cancelled upload');
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoadingFiles = true);

    try {
      final files = await _storageService.listFiles();
      files.sort((a, b) {
        try {
          final dateA = DateTime.parse(a.$createdAt ?? '');
          final dateB = DateTime.parse(b.$createdAt ?? '');
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });

      setState(() {
        _uploadedFiles = files;
        _isLoadingFiles = false;
      });
      debugPrint('Loaded ${files.length} files');
    } catch (e) {
      debugPrint('Error loading files: $e');
      setState(() => _isLoadingFiles = false);
      _showSnackBar(_getErrorMessage(e), backgroundColor: Colors.red);
    }
  }

  Future<void> _downloadFile(String fileId, String fileName) async {
    if (_isGuest) {
      _showSnackBar(
        'Chế độ Guest không được phép download file',
        backgroundColor: Colors.orange,
      );
      return;
    }

    _showSnackBar('Đang download file...');

    try {
      final bytes = await _storageService.downloadFileBytes(fileId);
      debugPrint('Downloaded ${bytes.length} bytes');

      if (kIsWeb) {
        await FilePicker.platform.saveFile(
          dialogTitle: 'Lưu file',
          fileName: fileName,
          bytes: bytes,
        );
        _showSnackBar('Đã tải xuống: $fileName', backgroundColor: Colors.green);
        return;
      }

      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        final savedPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Lưu file',
          fileName: fileName,
          bytes: bytes,
        );

        if (savedPath == null) {
          _showSnackBar(
            'Hoàn tất tải xuống: $fileName',
            backgroundColor: Colors.green,
          );
        } else {
          _showSnackBar(
            'Đã lưu file: $fileName',
            backgroundColor: Colors.green,
          );
        }
        return;
      }

      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Lưu file',
        fileName: fileName,
      );

      if (outputPath == null) {
        _showSnackBar('Đã hủy lưu file');
        return;
      }

      final outFile = File(outputPath);
      await outFile.writeAsBytes(bytes);
      _showSnackBar('Đã lưu file: $fileName', backgroundColor: Colors.green);
    } catch (e) {
      debugPrint('Error downloading file: $e');
      _showSnackBar(_getErrorMessage(e), backgroundColor: Colors.red);
    }
  }

  Future<void> _deleteFile(String fileId, String fileName) async {
    if (_isGuest) {
      _showSnackBar(
        'Chế độ Guest không được phép xóa file',
        backgroundColor: Colors.orange,
      );
      return;
    }

    final confirm = await _showDeleteConfirmation(fileName);
    if (confirm != true) return;

    try {
      await _storageService.deleteFile(fileId);
      _showSnackBar('Đã xóa file thành công!', backgroundColor: Colors.green);
      await _loadFiles();
    } catch (e) {
      _showSnackBar(_getErrorMessage(e), backgroundColor: Colors.red);
    }
  }

  Future<bool?> _showDeleteConfirmation(String fileName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Xác nhận xóa'),
          ],
        ),
        content: Text('Bạn có chắc muốn xóa file "$fileName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showFilesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(color: Colors.white),
        child: SafeArea(
          child: Column(
            children: [
              _buildBottomSheetHeader(),
              if (_uploadedFiles.isNotEmpty) _buildFileCount(),
              Expanded(child: _buildFileList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheetHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_upload, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          const Text(
            'Danh sách Files',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadFiles,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Đóng',
          ),
        ],
      ),
    );
  }

  Widget _buildFileCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Text(
            '${_uploadedFiles.length} files',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    if (_isLoadingFiles) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_uploadedFiles.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _uploadedFiles.length,
      itemBuilder: (context, index) => _buildFileItem(_uploadedFiles[index]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Chưa có file nào',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(dynamic file) {
    final fileName = file.name ?? 'Unknown';
    final fileId = file.$id;
    final fileSize = file.sizeOriginal ?? 0;
    final fileSizeKB = (fileSize / 1024).toStringAsFixed(2);
    final uploadTime = _formatUploadTime(file.$createdAt);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildFileIcon(),
        title: Text(
          fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: _buildFileDetails(fileSizeKB, uploadTime),
        trailing: _buildFileActions(fileId, fileName),
      ),
    );
  }

  Widget _buildFileIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.insert_drive_file,
        color: Colors.blue.shade700,
        size: 24,
      ),
    );
  }

  Widget _buildFileDetails(String fileSizeKB, String uploadTime) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$fileSizeKB KB',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            '📅 Tải lên: $uploadTime',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            '👤 ${_userName ?? 'Unknown user'}',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildFileActions(String fileId, String fileName) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            Icons.download,
            color: _isGuest ? Colors.grey : Colors.blue,
          ),
          tooltip: _isGuest ? 'Guest không được download' : 'Download',
          onPressed: _isGuest
              ? null
              : () {
                  Navigator.pop(context);
                  _downloadFile(fileId, fileName);
                },
        ),
        IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: _isGuest ? Colors.grey : Colors.red,
          ),
          tooltip: _isGuest ? 'Guest không được xóa' : 'Delete',
          onPressed: _isGuest
              ? null
              : () {
                  Navigator.pop(context);
                  _deleteFile(fileId, fileName);
                },
        ),
      ],
    );
  }

  String _formatUploadTime(String? createdAt) {
    if (createdAt == null) return 'Chưa rõ';

    try {
      final dateTime = DateTime.parse(createdAt).toLocal();
      return DateFormat('dd/MM/yyyy - HH:mm').format(dateTime);
    } catch (e) {
      return createdAt;
    }
  }

  Widget _buildUploadCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.cloud_upload_outlined,
              size: 80,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Upload File',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chọn và upload file của bạn',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedFileInfo() {
    if (_selectedFile == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.description, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedFile!.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${(_selectedFile!.size / 1024).toStringAsFixed(2)} KB',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (!_isUploading)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _selectedFile = null;
                  _status = 'Chưa chọn tệp...';
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    if (!_isUploading) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: _uploadProgress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isCancelling
                          ? [Colors.orange.shade400, Colors.orange.shade600]
                          : [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isCancelling
                    ? 'Đang hủy...'
                    : '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isCancelling
                      ? Colors.orange.shade700
                      : Colors.blue.shade700,
                ),
              ),
              if (!_isCancelling)
                TextButton.icon(
                  onPressed: _cancelUpload,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Hủy'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showFilesBottomSheet,
        icon: const Icon(Icons.list),
        label: Text('Files (${_uploadedFiles.length})'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                if (_isGuest)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Chế độ Guest: Bạn chỉ có thể xem danh sách file. Không thể upload, download hoặc xóa.',
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                _buildUploadCard(),
                const SizedBox(height: 32),
                _buildSelectedFileInfo(),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: (_isUploading || _isGuest) ? null : _pickFile,
                  icon: const Icon(Icons.folder_open),
                  label: Text(
                    _isGuest ? 'Chọn Tệp (Disabled)' : 'Chọn Tệp',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.blue.shade200, width: 2),
                    ),
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: 24),
                _buildProgressIndicator(),
                if (!_isUploading && _selectedFile == null)
                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        (_selectedFile != null && !_isUploading && !_isGuest)
                        ? _uploadFile
                        : null,
                    icon: const Icon(Icons.cloud_upload, size: 24),
                    label: Text(
                      _isGuest ? 'Upload (Disabled)' : 'Upload',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Firebase Storage Demo',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          if (_isGuest) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'GUEST',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
      centerTitle: true,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'logout') _logout();
          },
          offset: const Offset(0, 50),
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          _userName?.substring(0, 1).toUpperCase() ?? 'U',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userName ?? 'User',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _userId ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Đăng xuất'),
                ],
              ),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                _userName?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
