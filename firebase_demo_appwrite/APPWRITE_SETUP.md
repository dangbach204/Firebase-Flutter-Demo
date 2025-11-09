# AppWrite Setup Guide

This project has been migrated from Firebase to AppWrite. Follow these steps to complete the setup.

## Current Configuration

The following values are already configured in `lib/services/appwrite_client.dart`:

- **Endpoint:** `https://nyc.cloud.appwrite.io/v1`
- **Project ID:** `690e997d000355680a8e`

## Required Setup Steps

### 1. Create a Storage Bucket

You need to create a storage bucket in your AppWrite console:

1. Go to your AppWrite Console: https://cloud.appwrite.io/console
2. Select your project (ID: `690e997d000355680a8e`)
3. Navigate to **Storage** in the left sidebar
4. Click **Create Bucket**
5. Configure the bucket:
   - **Name:** Give it a meaningful name (e.g., "uploads" or "user-files")
   - **Bucket ID:** Copy the auto-generated ID or create a custom one
   - Click **Create**

### 2. Configure Bucket Permissions

For the app to work properly, you need to set the correct permissions:

1. Click on your newly created bucket
2. Go to the **Settings** tab
3. Under **Permissions**, add the following:

   - **Role:** `Any`
   - **Permissions:** Check `Create`, `Read`, `Update`, `Delete`

   OR for better security (recommended):

   - **Role:** `Users`
   - **Permissions:** Check `Create`, `Read`

   This allows authenticated users to upload and view files.

### 3. Update the Bucket ID in Code

Once you have your bucket ID:

1. Open `lib/services/appwrite_client.dart`
2. Replace `YOUR_BUCKET_ID_HERE` with your actual bucket ID:

```dart
static const String bucketId = 'your-actual-bucket-id';
```

### 4. Install Dependencies

Run the following command to install the required packages:

```bash
flutter pub get
```

### 5. Run the App

```bash
flutter run
```

## Features Migrated from Firebase

### Authentication

- ✅ Anonymous sign-in using AppWrite Account API
- User sessions are managed automatically by AppWrite

### Storage

- ✅ File upload with progress indication
- ✅ File download URLs
- ✅ Support for web and mobile platforms

## AppWrite SDK Usage

### Authentication (`lib/services/auth_service.dart`)

- Uses `Account.createAnonymousSession()` for anonymous authentication
- Checks for existing sessions before creating new ones
- Returns `models.User` object with user ID

### Storage (`lib/services/storage_service.dart`)

- `uploadFile()`: Uploads files and returns a file ID
- `getDownloadURL()`: Gets a view URL for the uploaded file
- `getFileDownload()`: Alternative method for download links

## Troubleshooting

### Error: "Bucket not found"

- Make sure you've created a bucket in the AppWrite console
- Verify the bucket ID in `appwrite_client.dart` matches your console

### Error: "Unauthorized"

- Check bucket permissions in the AppWrite console
- Ensure anonymous sessions are enabled in your project settings

### CORS Issues (Web)

If you're running on web and getting CORS errors:

1. Go to your AppWrite Console
2. Navigate to **Settings** > **Platforms**
3. Add your web platform:
   - **Type:** Web
   - **Name:** Your app name
   - **Hostname:** `localhost` (for development) or your production domain

### File Upload Fails

- Check that the bucket permissions allow `Create` for your user role
- Verify the file size doesn't exceed AppWrite's limits
- Check the console logs for detailed error messages

## Additional Resources

- [AppWrite Documentation](https://appwrite.io/docs)
- [AppWrite Flutter SDK](https://appwrite.io/docs/sdks#flutter)
- [AppWrite Storage Guide](https://appwrite.io/docs/products/storage)
- [AppWrite Authentication](https://appwrite.io/docs/products/auth)

## Security Recommendations

1. **Enable HTTPS only** in production
2. **Set proper bucket permissions** - avoid giving `Any` role all permissions
3. **Implement user authentication** - replace anonymous auth with email/OAuth
4. **Add file validation** - validate file types and sizes before upload
5. **Monitor usage** - track storage usage in AppWrite console
