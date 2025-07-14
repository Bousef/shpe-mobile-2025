
  //for firebase.json file, REPLACE B4 PUSHING!!!!
 //{"flutter":{"platforms":{"android":{"default":{"projectId":"shpemobile-5ac79","appId":"1:442807039058:android:1dff7903f638bb64db5b8b","fileOutput":"android/app/google-services.json"}},"ios":{"default":{"projectId":"shpemobile-5ac79","appId":"1:442807039058:ios:e86012146075bd86db5b8b","uploadDebugSymbols":false,"fileOutput":"ios/Runner/GoogleService-Info.plist"}},"dart":{"lib/firebase_options.dart":{"projectId":"shpemobile-5ac79","configurations":{"android":"1:442807039058:android:1dff7903f638bb64db5b8b","ios":"1:442807039058:ios:e86012146075bd86db5b8b"}}}}}}

 //USE THIS ONE FOR WINDOWS IN firebase.json
 //{"flutter":{"platforms":{"android":{"default":{"projectId":"shpemobile-5ac79000","appId":"1:625771134544:android:b1380aa2454079346c9b55","fileOutput":"android/app/google-services.json"}},"dart":{"lib/firebase_options.dart":{"projectId":"shpemobile-5ac79000","configurations":{"android":"1:625771134544:android:b1380aa2454079346c9b55","ios":"1:625771134544:ios:05b0b0b0dcd3959e6c9b55","macos":"1:625771134544:ios:05b0b0b0dcd3959e6c9b55","web":"1:625771134544:web:84cd2d3700252a9d6c9b55","windows":"1:625771134544:web:7f92d359b9f5caf96c9b55"}}}}}}

import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sign up using Firebase Auth
  Future<User?> signUp(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception("Sign-up failed: ${e.message}");
    }
  }

  /// Log in
  Future<User?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception("Login failed: ${e.message}");
    }
  }

  /// Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Log out
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Get Firebase ID token
  Future<String?> getIdToken() async {
    return await _auth.currentUser?.getIdToken();
  }
} 

/*import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sign up using Firebase Auth
  Future<User?> signUp(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception("Sign-up failed: ${e.message}");
    }
  }

  /// Log in
  Future<User?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception("Login failed: ${e.message}");
    }
  }

  /// Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Log out
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Get Firebase ID token
  Future<String?> getIdToken() async {
    return await _auth.currentUser?.getIdToken();
  }
}*/
