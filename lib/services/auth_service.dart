import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'data_manager.dart';
import 'firestore_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign Up
  static Future<String?> signUp(
      String email, String password, String name) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = cred.user;
      if (user != null) {
        await user.updateDisplayName(name);
        await user.sendEmailVerification();
        // Sync Firestore
        await FirestoreService.syncUser(user);
        return null;
      }
      return "User creation failed";
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      if (e.toString().contains("Identity Toolkit")) {
        return "Authentication disabled in Firebase Console.";
      }
      return e.toString();
    }
  }

  // Login
  static Future<String?> login(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = cred.user;
      if (user != null) {
        if (!user.emailVerified) {
          await user.sendEmailVerification();
          return "Email not verified. Verification link sent!";
        }
        // Sync Firestore
        await FirestoreService.syncUser(user);
        return null;
      }
      return "Login failed";
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // Google Login
  static Future<String?> googleLogin() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return "Sign in cancelled";

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential cred = await _auth.signInWithCredential(credential);
      User? user = cred.user;

      if (user != null) {
        // Sync Firestore
        await FirestoreService.syncUser(user);
        return null;
      }
      return "Google Sign-In Failed";
    } catch (e) {
      if (e.toString().contains("ApiException: 10")) {
        return "Google Sign-In Error: SHA-1 Key Missing in Console.";
      }
      return e.toString();
    }
  }

  // Forgot Password
  static Future<String?> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // Logout
  static Future<void> logout() async {
    try {
      // SAVE DATA BEFORE LOGOUT
      await FirestoreService.saveUserData();
      await DataManager.resetProfile();
    } catch (e) {
      print("Reset Profile Error: $e");
    }

    try {
      await _auth.signOut();
    } catch (e) {
      print("SignOut Error: $e");
    }

    // Default to guest true temporarily until AuthScreen decides next step
    DataManager.isGuest = true;
  }
}
