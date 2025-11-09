# Firebase Demo - Upload File

Ứng dụng Flutter demo cho việc upload file lên Firebase Storage.

## Tính năng

- ✅ Đăng nhập ẩn danh (Anonymous Authentication)
- ✅ Chọn file từ thiết bị
- ✅ Upload file lên Firebase Storage
- ✅ Hiển thị tiến trình upload
- ✅ Hủy upload
- ✅ Lưu metadata (uploader ID) cho file
- ✅ **Hỗ trợ đa nền tảng** (Web, Android, iOS, Desktop)

## Cấu trúc Project

```
lib/
├── firebase_options.dart       # Cấu hình Firebase
├── main.dart                   # Entry point
├── screens/
│   └── upload_screen.dart      # Màn hình upload file
└── services/
    ├── auth_service.dart       # Service xác thực
    └── storage_service.dart    # Service upload file
```

## Dependencies

- `firebase_core` - Firebase core
- `firebase_auth` - Xác thực Firebase
- `firebase_storage` - Lưu trữ Firebase
- `file_picker` - Chọn file từ thiết bị

## Cài đặt

1. Clone project
2. Chạy `flutter pub get`
3. Cấu hình Firebase cho project của bạn
4. Chạy app: `flutter run` hoặc `flutter run -d chrome` (cho Web)

## Các thay đổi gần đây

### ✅ Đã sửa lỗi

- **"unsupported operation: \_namespace"**: Sửa lỗi Web bằng cách thay `File` (dart:io) thành `PlatformFile` (hỗ trợ đa nền tảng)
- **Bug nghiêm trọng**: Sửa lỗi ép kiểu sai `File as Uint8List` thành `await file.readAsBytes()`
- **Warning**: Đổi `_UploadScreenState` thành `UploadScreenState` (public state class)

### 🗑️ Đã xóa

- `cloud_firestore` dependency (không sử dụng)
- `lib/services/firestore_service.dart` (không sử dụng)
- `lib/models/file_models.dart` (không sử dụng)
- `lib/models/` directory (rỗng)
- `*.iml` files (IntelliJ IDEA project files)
- `dart:io` import (không tương thích với Web)

### 🎨 Đã tối ưu

- Thêm `const` cho widgets không thay đổi
- Làm sạch code và imports không cần thiết
- **Sử dụng `PlatformFile.bytes`** thay vì `File.readAsBytes()` để hỗ trợ Web

## Lưu ý

- App sử dụng Anonymous Authentication, user ID sẽ khác nhau mỗi lần cài đặt lại
- File được upload lên thư mục `uploads/` trong Firebase Storage
- Metadata `uploaderId` được lưu kèm theo file
- **App hoạt động trên cả Web, Mobile và Desktop** nhờ sử dụng `PlatformFile` thay vì `File`
