import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/data/models/user_model.dart';

final authProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authProvider).authStateChanges();
});

final signInProvider = FutureProvider.family<void, (String email, String password)>((ref, credentials) async {
  final auth = ref.watch(authProvider);
  final (email, password) = credentials;
  await auth.signInWithEmailAndPassword(email: email, password: password);
});

final signUpProvider = FutureProvider.family<void, (String email, String password)>((ref, credentials) async {
  final auth = ref.watch(authProvider);
  final (email, password) = credentials;

  await auth.createUserWithEmailAndPassword(email: email, password: password);
});

final userModelProvider = FutureProvider<UserModel>((ref) async {
  final auth = ref.watch(authProvider);
  final firestore = ref.watch(firestoreProvider);
  final user = auth.currentUser;

  if (user == null) throw Exception("Usuario no autenticado");
  final doc = await firestore.collection('usuario').doc(user.uid).get();
  if (!doc.exists) throw Exception("Usuario no encontrado en Firestore");
  final data = doc.data()!;

  return UserModel.fromMap(data, user.uid);
});