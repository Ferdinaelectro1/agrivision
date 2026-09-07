abstract class AuthService {
  Stream<AppUser?> get authStateChanges;
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({required String email, required String password});
  Future<void> signOut();
}

class AppUser {
  final String uid;
  final String? email;
  AppUser({required this.uid, this.email});
}