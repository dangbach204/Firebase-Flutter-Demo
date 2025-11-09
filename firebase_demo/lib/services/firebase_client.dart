import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_storage/firebase_storage.dart' as fb_storage;

class FirebaseService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    await Firebase.initializeApp();
    _initialized = true;
  }

  static fb_auth.FirebaseAuth get auth => fb_auth.FirebaseAuth.instance;

  static fb_storage.FirebaseStorage get storage =>
      fb_storage.FirebaseStorage.instance;
}
