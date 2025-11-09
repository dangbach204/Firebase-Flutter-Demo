import 'package:firebase_demo/screens/login_screen.dart';
import 'package:firebase_demo/services/auth_service.dart';
import 'package:firebase_demo/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart' as fb_storage;

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  UploadScreenState createState() => UploadScreenState();
}

class UploadScreenState extends State<UploadScreen> {
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _status = 'Chưa chọn tệp...';
  List<dynamic> _uploadedFiles = [];
  bool _isLoadingFiles = false;

  // Services
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();

  // User info
  String? _userId;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    await _getUserId();
    await _loadFiles();
  }

  Future<void> _getUserId() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        setState(() {
          _userId = user.$id;
          _userName = user.name;
        });
        debugPrint('User ID: $_userId, Name: $_userName');
      } else {
        _updateStatus('Lỗi: Chưa đăng nhập. Vui lòng khởi động lại app.');
        debugPrint('Không tìm thấy người dùng đã đăng nhập.');
      }
    } catch (e) {
      _updateStatus('Lỗi: Không thể lấy thông tin người dùng.');
      debugPrint('Lỗi khi lấy thông tin user: $e');
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is fb_storage.FirebaseException) {
      return _handleFirebaseStorageError(error);
    }

    if (error is FirebaseException) {
      final msg = error.message ?? error.toString();
      if (msg.toLowerCase().contains('permission')) {
        return 'Lỗi quyền hạn: $msg';
      }
      return msg;
    }

    return error.toString();
  }

  String _handleFirebaseStorageError(fb_storage.FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
      case 'unauthorized':
        return 'Bạn không có quyền thực hiện thao tác này. Vui lòng đăng nhập lại.';
      case 'not-found':
        return 'Không tìm thấy file hoặc bucket.';
      default:
        return error.message ?? 'Đã xảy ra lỗi: ${error.code}';
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _selectedFile = result.files.single;
          _status = 'Đã chọn tệp: ${result.files.single.name}';
        });
      } else {
        _updateStatus('Không chọn tệp nào.');
      }
    } catch (e) {
      _updateStatus('Lỗi khi chọn tệp: $e');
    }
  }

  Future<void> _uploadFile() async {
    if (!_validateUpload()) return;

    final fileName = _selectedFile!.name;
    final fileBytes = _selectedFile!.bytes;

    if (fileBytes == null) {
      _showError('Lỗi: Không thể đọc file.');
      return;
    }

    try {
      _startUpload();

      final fileId = await _storageService.uploadFile(
        fileName,
        fileBytes,
        uploaderId: _userId,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
            final percentage = (progress * 100).round();
            _status = 'Đang upload... $percentage%';
          });
        },
      );

      await _completeUpload(fileId, fileName);
    } catch (e) {
      _handleUploadError(e);
    }
  }

  bool _validateUpload() {
    if (_selectedFile == null) {
      _showSnackBar('Vui lòng chọn một tệp trước!');
      return false;
    }

    if (_userId == null) {
      _showSnackBar('Lỗi: Không tìm thấy ID người dùng. Vui lòng thử lại.');
      return false;
    }

    return true;
  }

  void _startUpload() {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _status = 'Đang upload... 0%';
    });
  }

  Future<void> _completeUpload(String? fileId, String fileName) async {
    setState(() {
      _uploadProgress = 1.0;
      _status = 'Đang upload... 100%';
    });

    if (fileId == null) {
      _showError('Upload thất bại: Không nhận được file ID');
      return;
    }

    final downloadUrl = await _storageService.getDownloadURL(fileId);

    setState(() {
      _status = 'Upload thành công!';
      _isUploading = false;
    });

    debugPrint('File ID: $fileId');
    debugPrint('URL Tải xuống: $downloadUrl');

    _showSnackBar('Upload thành công! File ID: $fileId', isSuccess: true);
    await _loadFiles();
  }

  void _handleUploadError(dynamic error) {
    final errorMessage = _getErrorMessage(error);
    setState(() {
      _status = 'Upload thất bại: $errorMessage';
      _isUploading = false;
      _uploadProgress = 0.0;
    });

    _showSnackBar(errorMessage, isError: true, duration: 5);
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoadingFiles = true);

    try {
      final files = await _storageService.listFiles();
      _sortFilesByDate(files);

      setState(() {
        _uploadedFiles = files;
        _isLoadingFiles = false;
      });

      debugPrint('Loaded ${files.length} files');
    } catch (e) {
      debugPrint('Error loading files: $e');
      setState(() => _isLoadingFiles = false);
      _showSnackBar(_getErrorMessage(e), isError: true, duration: 5);
    }
  }

  void _sortFilesByDate(List<dynamic> files) {
    files.sort((a, b) {
      try {
        final dateA = DateTime.parse(a.$createdAt ?? '');
        final dateB = DateTime.parse(b.$createdAt ?? '');
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });
  }

  Future<void> _downloadFile(String fileId, String fileName) async {
    try {
      _showSnackBar('Đang download file...');

      final Uint8List bytes = await _storageService.downloadFileBytes(fileId);
      debugPrint('Downloaded ${bytes.length} bytes');

      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Lưu file',
        fileName: fileName,
        bytes: bytes,
      );

      if (outputPath != null) {
        _showSnackBar('Đã lưu file: $fileName', isSuccess: true, duration: 2);
      } else {
        _showSnackBar('Đã hủy download');
      }
    } catch (e) {
      debugPrint('Error downloading file: $e');
      _showSnackBar(_getErrorMessage(e), isError: true, duration: 5);
    }
  }

  Future<void> _deleteFile(String fileId, String fileName) async {
    final confirmed = await _showDeleteConfirmation(fileName);
    if (!confirmed) return;

    try {
      await _storageService.deleteFile(fileId);
      _showSnackBar('Đã xóa file thành công!', isSuccess: true);
      await _loadFiles();
    } catch (e) {
      _showSnackBar(_getErrorMessage(e), isError: true, duration: 5);
    }
  }

  Future<bool> _showDeleteConfirmation(String fileName) async {
    final result = await showDialog<bool>(
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

    return result ?? false;
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
      _showSnackBar('Logout failed: $e', isError: true);
    }
  }

  void _updateStatus(String status) {
    setState(() => _status = status);
  }

  void _showError(String message) {
    setState(() {
      _status = message;
      _isUploading = false;
      _uploadProgress = 0.0;
    });
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
    int duration = 3,
  }) {
    if (!mounted) return;

    Color? backgroundColor;
    if (isError) backgroundColor = Colors.red;
    if (isSuccess) backgroundColor = Colors.green;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: duration),
      ),
    );
  }

  void _showFilesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilesBottomSheet(
        uploadedFiles: _uploadedFiles,
        isLoadingFiles: _isLoadingFiles,
        userName: _userName,
        onRefresh: _loadFiles,
        onDownload: _downloadFile,
        onDelete: _deleteFile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      floatingActionButton: _buildFloatingActionButton(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      title: const Text(
        'Firebase Storage',
        style: TextStyle(fontWeight: FontWeight.w600),
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
      actions: [_buildUserMenu()],
    );
  }

  Widget _buildUserMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'logout') _logout();
      },
      offset: const Offset(0, 50),
      itemBuilder: (context) => [
        PopupMenuItem<String>(enabled: false, child: _buildUserInfo()),
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
    );
  }

  Widget _buildUserInfo() {
    return Column(
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
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showFilesBottomSheet,
      icon: const Icon(Icons.list),
      label: Text('Files (${_uploadedFiles.length})'),
      backgroundColor: Colors.blue.shade700,
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              _buildHeaderCard(),
              const SizedBox(height: 32),
              if (_selectedFile != null) _buildSelectedFileCard(),
              const SizedBox(height: 24),
              _buildPickFileButton(),
              const SizedBox(height: 24),
              if (_isUploading)
                _buildProgressIndicator()
              else if (_selectedFile == null)
                _buildStatusText(),
              const SizedBox(height: 24),
              _buildUploadButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
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

  Widget _buildSelectedFileCard() {
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

  Widget _buildPickFileButton() {
    return ElevatedButton.icon(
      onPressed: _isUploading ? null : _pickFile,
      icon: const Icon(Icons.folder_open),
      label: const Text(
        'Chọn Tệp',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.blue.shade200, width: 2),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _buildProgressIndicator() {
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
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${(_uploadProgress * 100).round()}%',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusText() {
    return Text(
      _status,
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
    );
  }

  Widget _buildUploadButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (_selectedFile != null && !_isUploading)
            ? _uploadFile
            : null,
        icon: const Icon(Icons.cloud_upload, size: 24),
        label: const Text(
          'Upload',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    );
  }
}

class _FilesBottomSheet extends StatelessWidget {
  final List<dynamic> uploadedFiles;
  final bool isLoadingFiles;
  final String? userName;
  final VoidCallback onRefresh;
  final Function(String, String) onDownload;
  final Function(String, String) onDelete;

  const _FilesBottomSheet({
    required this.uploadedFiles,
    required this.isLoadingFiles,
    required this.userName,
    required this.onRefresh,
    required this.onDownload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(color: Colors.white),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            if (uploadedFiles.isNotEmpty) _buildFileCount(),
            Expanded(child: _buildFileList(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            onPressed: onRefresh,
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
            '${uploadedFiles.length} files',
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

  Widget _buildFileList(BuildContext context) {
    if (isLoadingFiles) {
      return const Center(child: CircularProgressIndicator());
    }

    if (uploadedFiles.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: uploadedFiles.length,
      itemBuilder: (context, index) => _buildFileItem(context, index),
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

  Widget _buildFileItem(BuildContext context, int index) {
    final file = uploadedFiles[index];
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
        border: Border.all(color: Colors.grey.shade200, width: 1),
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
        leading: Container(
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
        ),
        title: Text(
          fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: _buildFileSubtitle(fileSizeKB, uploadTime),
        trailing: _buildFileActions(context, fileId, fileName),
      ),
    );
  }

  Widget _buildFileSubtitle(String fileSizeKB, String uploadTime) {
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
            '👤 ${userName ?? 'Unknown user'}',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildFileActions(
    BuildContext context,
    String fileId,
    String fileName,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.download),
          color: Colors.blue,
          tooltip: 'Download',
          onPressed: () {
            Navigator.pop(context);
            onDownload(fileId, fileName);
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          color: Colors.red,
          tooltip: 'Delete',
          onPressed: () {
            Navigator.pop(context);
            onDelete(fileId, fileName);
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
}
