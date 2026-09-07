import 'dart:async';
import 'auth_service.dart';

class FakeAuthService implements AuthService {
  final _controller = StreamController<AppUser?>.broadcast();

  FakeAuthService() {
    // état initial : personne n'est connecté
    _controller.add(null);
  }

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 800)); // simule un appel réseau
    _controller.add(AppUser(uid: 'fake-uid', email: email));
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _controller.add(AppUser(uid: 'fake-uid', email: email));
  }

  @override
  Future<void> signOut() async {
    _controller.add(null);
  }
}