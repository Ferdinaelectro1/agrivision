import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_service.dart';

class FirebaseAuthServiceImpl implements AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final GoogleSignIn _google = GoogleSignIn.instance;

  /// À appeler UNE SEULE FOIS au démarrage, avant tout signInWithGoogle().
  Future<void> initGoogle() async {
    await _google.initialize(
      serverClientId: '390419841327-7ns5c5j0dnihrjauritr2594ah7e3iki.apps.googleusercontent.com',
    );
  }

  @override
  Stream<AppUser?> get authStateChanges => _auth.authStateChanges().map(
        (user) => user == null ? null : AppUser(uid: user.uid, email: user.email),
      );

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> signInWithGoogle() async {
    // 1. Authentification Google (ouvre la feuille Credential Manager)
    final GoogleSignInAccount account = await _google.authenticate();

    // 2. Récupération de l'idToken (synchrone en v7)
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw Exception('idToken null — vérifie le serverClientId et le SHA-1');
    }

    // 3. Échange contre un credential Firebase
    final credential = fb.GoogleAuthProvider.credential(idToken: idToken);
    await _auth.signInWithCredential(credential);
    // le StreamBuilder de main.dart route automatiquement vers HomeScreen
  }

  @override
  Future<void> signOut() async {
    await _google.signOut();
    await _auth.signOut();
  }
}