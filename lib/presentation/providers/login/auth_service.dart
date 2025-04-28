import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Método para iniciar sesión
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Puedes personalizar los errores que quieras manejar
      if (e.code == 'user-not-found') {
        throw Exception('No existe un usuario con ese correo.');
      } else if (e.code == 'wrong-password') {
        throw Exception('La contraseña es incorrecta.');
      } else {
        throw Exception('Error al iniciar sesión: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  // Método opcional: cerrar sesión
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // Método opcional: obtener el usuario actual
  User? get currentUser => _firebaseAuth.currentUser;
}
