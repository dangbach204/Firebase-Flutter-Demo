# Authentication Guide

## Features Added

Your AppWrite app now includes full authentication with login and registration!

---

## Authentication Features

### ✅ User Registration

- **Screen:** `RegisterScreen`
- **Fields:** Full Name, Email, Password, Confirm Password
- **Validation:** Email format, password strength (min 8 chars), password match
- **Auto-login:** Users are automatically logged in after successful registration

### ✅ User Login

- **Screen:** `LoginScreen`
- **Fields:** Email, Password
- **Features:** Password visibility toggle, form validation
- **Session:** Persists across app restarts

### ✅ User Logout

- **Location:** AppBar in UploadScreen (logout icon button)
- **Action:** Clears session and redirects to login screen

### ✅ Auth State Management

- **Auto-check:** App checks login status on startup
- **Route:** Logged in → UploadScreen, Not logged in → LoginScreen
- **User Info:** Display user name and ID in UploadScreen

---

## Files Modified/Created

### New Files

1. **`lib/screens/login_screen.dart`** - Login UI with email/password
2. **`lib/screens/register_screen.dart`** - Registration UI
3. **`AUTH_GUIDE.md`** - This file

### Modified Files

1. **`lib/services/auth_service.dart`**

   - Added `register()` - Create new user account
   - Added `login()` - Email/password authentication
   - Added `logout()` - Delete current session
   - Added `isLoggedIn()` - Check auth status
   - Added `getCurrentUser()` - Get user details
   - Kept `signInAnonymously()` for testing

2. **`lib/screens/upload_screen.dart`**

   - Added logout button in AppBar
   - Added user info card showing name and ID
   - Updated to handle user sessions

3. **`lib/main.dart`**
   - Added `AuthChecker` widget to check login status
   - Routes to LoginScreen or UploadScreen based on auth state
   - Removed automatic anonymous sign-in

---

## How to Use

### First Time Setup

1. **Run the app:**

   ```bash
   flutter run
   ```

2. **Create an account:**

   - Click "Register" on the login screen
   - Fill in your details (name, email, password)
   - Click "Register" button
   - You'll be automatically logged in

3. **Upload files:**

   - After login, you'll see the upload screen
   - Your name will appear in the AppBar
   - Use the app as before

4. **Logout:**
   - Click the logout icon in the AppBar
   - You'll be redirected to the login screen

### Returning User

1. **Login:**
   - Enter your email and password
   - Click "Login"
   - Access your files

---

## Authentication Flow

```
App Start
    ↓
Initialize AppWrite
    ↓
Check Auth Status
    ↓
├─ Logged In → UploadScreen
└─ Not Logged In → LoginScreen
    ↓
    ├─ Login → Enter credentials → UploadScreen
    └─ Register → Create account → UploadScreen
        ↓
        Logout → LoginScreen
```

---

## AppWrite Configuration

### Required Settings in AppWrite Console

1. **Go to:** https://cloud.appwrite.io/console
2. **Select your project:** `690e997d000355680a8e`
3. **Navigate to:** Auth → Settings

### Recommended Settings

- ✅ **Email/Password:** Enabled (default)
- ⬜ **Email Verification:** Optional (requires email service setup)
- ⬜ **Personal Data:** Check if you want to collect user data
- ✅ **Session Length:** 365 days (adjust as needed)

### Security Settings

For production apps, consider:

- Enable email verification
- Set session expiry limits
- Implement password reset
- Add rate limiting
- Use HTTPS only

---

## API Reference

### AuthService Methods

```dart
// Register new user
await authService.register(
  email: 'user@example.com',
  password: 'securePassword123',
  name: 'John Doe',
);

// Login existing user
await authService.login(
  email: 'user@example.com',
  password: 'securePassword123',
);

// Logout
await authService.logout();

// Check if logged in
bool isLoggedIn = await authService.isLoggedIn();

// Get current user
models.User? user = await authService.getCurrentUser();

// Access user properties
String userId = user?.$id;
String userName = user?.name;
String userEmail = user?.email;
```

---

## Error Handling

### Common Errors

**"User already exists"**

- This email is already registered
- Try logging in instead or use a different email

**"Invalid credentials"**

- Email or password is incorrect
- Check your credentials and try again

**"User (role: guests) missing scope (account)"**

- Session expired or doesn't exist
- Login again to create a new session

**"Password must be at least 8 characters"**

- AppWrite requires minimum 8 characters
- Use a stronger password

---

## Next Steps

### Recommended Enhancements

1. **Email Verification**

   - Verify user emails after registration
   - Prevent fake accounts

2. **Password Reset**

   - Add "Forgot Password?" link
   - Implement password recovery flow

3. **OAuth Login**

   - Add Google, GitHub, or other OAuth providers
   - Simplify login process

4. **Profile Management**

   - Add screen to update user profile
   - Change password functionality

5. **Remember Me**

   - Add checkbox to extend session
   - Implement secure token storage

6. **2FA (Two-Factor Authentication)**
   - Add extra security layer
   - Protect sensitive accounts

---

## Testing

### Test Accounts

Create test accounts to verify:

- ✅ Registration with valid data
- ✅ Registration with duplicate email (should fail)
- ✅ Login with correct credentials
- ✅ Login with wrong password (should fail)
- ✅ Session persistence (close and reopen app)
- ✅ Logout functionality
- ✅ File upload as authenticated user

---

## Troubleshooting

### Can't Register New User

**Check:**

1. Email format is valid
2. Password is at least 8 characters
3. Passwords match in both fields
4. Internet connection is active
5. AppWrite project is accessible

### Can't Login

**Check:**

1. Email and password are correct (case-sensitive)
2. Account exists (try registering first)
3. No typos in credentials
4. AppWrite endpoint is correct in `appwrite_client.dart`

### Session Doesn't Persist

**Check:**

1. AppWrite session settings in console
2. No errors in debug console
3. App has network permission
4. Session hasn't expired

---

## Security Best Practices

1. **Never hardcode credentials** in your source code
2. **Use HTTPS** for all API calls (already configured)
3. **Validate input** on both client and server
4. **Implement rate limiting** to prevent brute force
5. **Use strong passwords** (enforce in validation)
6. **Handle errors gracefully** without exposing system details
7. **Keep dependencies updated** regularly
8. **Monitor auth logs** in AppWrite console

---

**Authentication is now fully functional!** 🎉

Users can register, login, and logout securely using AppWrite's authentication system.
