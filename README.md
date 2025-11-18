# Firebase & Appwrite Flutter Storage Demo

A comprehensive Flutter project demonstrating image upload and display using both **Firebase Storage** and **Appwrite Storage**. This repository helps developers choose and implement the right backend storage solution for their Flutter applications.

## Table of Contents

- [Overview](#-overview)
- [Why This Project?](#-why-this-project)
- [Repository Structure](#-repository-structure)
- [Prerequisites](#-prerequisites)
- [Getting Started](#-getting-started)
  - [Firebase Storage Demo](#-firebase-storage-demo)
  - [Appwrite Storage Demo](#-appwrite-storage-demo)
- [Features](#-features)
- [Comparison](#-firebase-vs-appwrite-comparison)
- [Screenshots](#-screenshots)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)
- [Support](#-support)

## Overview

This project provides **two complete, working demos** that showcase how to integrate image storage services with Flutter:

1. **Firebase Storage Demo** - Industry-standard solution with extensive documentation
2. **Appwrite Storage Demo** - Free, open-source alternative with cloud and self-hosting options

Both demos include complete implementations of:

- Image selection from device gallery
- Image upload to cloud storage
- Image retrieval and display
- Error handling and loading states
- Clean, production-ready code structure

## Why This Project?

Firebase Storage recently removed its free tier, making it costly for small projects and indie developers. This repository was created to:

- Provide a **free alternative** (Appwrite) with similar functionality
- Offer **side-by-side comparison** of both services
- Include **complete, runnable code** for both platforms
- Help developers **migrate** from Firebase to Appwrite if needed
- Demonstrate **best practices** for Flutter storage integration

## Repository Structure

```
Firebase-Flutter-Demo/
│
├── firebase_storage_demo/          # Firebase Storage implementation
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   │   └── upload_screen.dart
│   │   ├── services/
│   │   │   └── firebase_storage_service.dart
│   │   └── widgets/
│   ├── android/
│   ├── ios/
│   ├── pubspec.yaml
│   └── README.md
│
├── appwrite_storage_demo/          # Appwrite Storage implementation
│   ├── lib/
│   │   ├── main.dart
│   │   ├── config/
│   │   │   └── appwrite_config.dart
│   │   ├── screens/
│   │   │   └── upload_screen.dart
│   │   ├── services/
│   │   │   └── appwrite_storage_service.dart
│   │   └── widgets/
│   ├── android/
│   ├── ios/
│   ├── pubspec.yaml
│   └── README.md
│
├── .gitignore
├── LICENSE
└── README.md
```

## Prerequisites

Before running either demo, ensure you have:

- **Flutter SDK** (3.0.0 or higher)
  ```bash
  flutter --version
  ```
- **Dart SDK** (included with Flutter)
- **Android Studio** / **Xcode** (for mobile development)
- **Git** for cloning the repository
- A **Firebase account** (for Firebase demo) or **Appwrite Cloud account** (for Appwrite demo)

## Getting Started

### Clone the Repository

```bash
git clone https://github.com/dangbach204/Firebase-Flutter-Demo.git
cd Firebase-Flutter-Demo
```

---

## Firebase Storage Demo

### Step 1: Install Dependencies

```bash
cd firebase_storage_demo
flutter pub get
```

### Step 2: Configure Firebase

#### A. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** and follow the setup wizard
3. Once created, click on your project to open the dashboard

#### B. Add Flutter App to Firebase

**For Android:**

1. Click the **Android icon** in your Firebase project overview
2. Enter your package name (found in `android/app/build.gradle`)
3. Download `google-services.json`
4. Place it in `android/app/` directory

**For iOS:**

1. Click the **iOS icon** in your Firebase project overview
2. Enter your bundle ID (found in Xcode or `ios/Runner/Info.plist`)
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/` directory

#### C. Enable Firebase Storage

1. In Firebase Console, go to **"Storage"** from the left menu
2. Click **"Get Started"**
3. Choose your storage location
4. Click **"Done"**

#### D. Configure Storage Rules (Development Only)

**Warning:** Use secure rules in production!

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null; // Requires authentication
      // Or for testing only:
      // allow read, write: if true;
    }
  }
}
```

### Step 3: Update Firebase Configuration (if needed)

Open `lib/services/firebase_storage_service.dart` and verify your Firebase initialization:

```dart
import 'package:firebase_core/firebase_core.dart';

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### Step 4: Run the App

```bash
flutter run
```

### Firebase Demo Features

- Pick images/files from gallery
- Upload to Firebase Storage with progress indicator
- Generate download URLs
- Display uploaded images
- Optional Firebase Authentication integration
- Error handling with user-friendly messages

---

## Appwrite Storage Demo

### Step 1: Install Dependencies

```bash
cd appwrite_storage_demo
flutter pub get
```

### Step 2: Setup Appwrite

#### Option 1: Appwrite Cloud (Recommended)

1. Visit [Appwrite Cloud](https://cloud.appwrite.io/)
2. Create a free account
3. Create a new project
4. Note your **Project ID** and **API Endpoint**

#### Option 2: Self-Hosted (Advanced)

```bash
docker run -it --rm \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --volume "$(pwd)"/appwrite:/usr/src/code/appwrite:rw \
  --entrypoint="install" \
  appwrite/appwrite:1.4.13
```

Access Appwrite at `http://localhost` after installation.

### Step 3: Create Storage Bucket

1. In your Appwrite Console, go to **Storage**
2. Click **"Create Bucket"**
3. Give it a name (e.g., "images")
4. Configure permissions:
   - **Read access**: `Role: Any`
   - **Write access**: `Role: Any` (for testing) or `Role: Users` (recommended)
5. Note your **Bucket ID**

### Step 4: Configure Flutter App

Open `lib/config/appwrite_config.dart` and update:

```dart
class AppwriteConfig {
  static const String endpoint = 'https://cloud.appwrite.io/v1'; // Your endpoint
  static const String projectId = 'YOUR_PROJECT_ID';              // Your project ID
  static const String bucketId = 'YOUR_BUCKET_ID';                // Your bucket ID
}
```

### Step 5: Run the App

```bash
flutter run
```

### Appwrite Demo Features

- Pick images/files from gallery
- Upload to Appwrite Storage with progress tracking
- Generate file preview URLs
- Display uploaded images
- Delete uploaded files
- File size and type validation
- Comprehensive error handling

---

## Features

Both demos include:

| Feature                  | Firebase Demo | Appwrite Demo |
| ------------------------ | ------------- | ------------- |
| Image Picker Integration | yes           | yes           |
| Image Upload             | yes           | yes           |
| Progress Indicator       | yes           | yes           |
| Display Uploaded Images  | yes           | yes           |
| Error Handling           | yes           | yes           |
| Loading States           | yes           | yes           |
| Clean Architecture       | yes           | yes           |
| Commented Code           | yes           | yes           |
| File Deletion            | x             | yes           |
| File Metadata            | Basic         | Detailed      |

## ⚖️ Firebase vs Appwrite Comparison

| Aspect                         | Firebase Storage             | Appwrite Storage    |
| ------------------------------ | ---------------------------- | ------------------- |
| **Pricing**                    | No free tier (Pay-as-you-go) | Free tier available |
| **Self-Hosting**               | Not available                | Docker support      |
| **Setup Complexity**           | Easy                         | Easy                |
| **Documentation**              | Excellent                    | Very Good           |
| **Community**                  | Very Large                   | Growing             |
| **File Upload**                | Yes                          | Yes                 |
| **File Download**              | Yes                          | Yes                 |
| **Security Rules**             | Flexible                     | Flexible            |
| **CDN**                        | Global                       | Global (Cloud)      |
| **Flutter SDK**                | Official                     | Official            |
| **Real-time Updates**          | Limited                      | Webhooks            |
| **Image Transformation**       | Needs extensions             | Built-in            |
| **Max File Size**              | 5GB                          | Configurable        |
| **Authentication Integration** | Seamless                     | Seamless            |

### Cost Comparison (Monthly)

**Firebase Storage:**

- Storage: $0.026/GB
- Download: $0.12/GB
- Upload: $0.05/GB
- No free tier

**Appwrite Cloud:**

- Free tier: 2GB storage, 10GB bandwidth
- Pro: $15/month (50GB storage, 300GB bandwidth)
- Scale: Custom pricing

**Verdict:** Appwrite is significantly more cost-effective for small to medium projects.

## Screenshots

_Add screenshots of your app here showing:_

- Image picker interface
- Upload progress
- Uploaded image display
- Error states
- Success messages

## Troubleshooting

### Firebase Issues

**Problem:** `google-services.json` not found

```bash
Solution: Ensure the file is in android/app/ directory and run:
flutter clean
flutter pub get
```

**Problem:** Firebase initialization failed

```bash
Solution: Check your Firebase configuration and ensure FlutterFire CLI is set up:
dart pub global activate flutterfire_cli
flutterfire configure
```

### Appwrite Issues

**Problem:** Connection refused

```bash
Solution: Verify your endpoint URL and ensure Appwrite server is running
```

**Problem:** Invalid bucket permissions

```bash
Solution: In Appwrite Console → Storage → Your Bucket → Settings
Add permissions for "Any" or "Users" role
```

### Common Issues

**Problem:** Image picker not working

```bash
Solution: Add permissions to AndroidManifest.xml and Info.plist:

Android (android/app/src/main/AndroidManifest.xml):
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>

iOS (ios/Runner/Info.plist):
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to upload images</string>
```

## Contributing

Contributions are welcome! Here's how you can help:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add some amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Areas for Contribution

- Add video upload support
- Implement file compression
- Add image filters/editing
- Create additional storage provider demos (AWS S3, Azure, etc.)
- Improve UI/UX
- Add tests
- Translate documentation

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you find this project helpful:

- **Star** the repository on GitHub
- **Share** it with other developers
- **Follow** for more Flutter projects
- **Report issues** or suggest features

## Contact

- **GitHub:** [@dangbach204](https://github.com/dangbach204)
- **Repository:** [Firebase-Flutter-Demo](https://github.com/dangbach204/Firebase-Flutter-Demo)

## Acknowledgments

- Flutter team for the amazing framework
- Firebase team for the robust backend services
- Appwrite team for the excellent open-source alternative
- All contributors and supporters of this project
