import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:restaurante_app/core/constants/app_constants.dart';
import 'package:restaurante_app/data/models/user_model.dart';

class RegisterUserController {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController apellidosController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController direccionController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void dispose() {
    nombreController.dispose();
    apellidosController.dispose();
    telefonoController.dispose();
    direccionController.dispose();
    userNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  bool areFieldsContactDataValid() {
    final nombre = nombreController.text.trim();
    final apellidos = apellidosController.text.trim();
    final telefono = telefonoController.text.trim();
    final direccion = direccionController.text.trim();
    return AppConstants.nameRegex.hasMatch(nombre) &&
         AppConstants.surnameRegex.hasMatch(apellidos) &&
         AppConstants.phoneRegex.hasMatch(telefono) &&
         AppConstants.addressRegex.hasMatch(direccion);
  }

  bool areFieldsAccesDataValid(){
    final userName = userNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    return AppConstants.usernameRegex.hasMatch(userName) &&
         AppConstants.emailRegex.hasMatch(email) &&
         AppConstants.passwordRegex.hasMatch(password);
  }

  Future<String?> registrarUsuario( WidgetRef ref, {
    required String nombre,
    required String apellidos,
    required String telefono,
    required String direccion,
    required String username,
    required String email,
    required String password,
    required String rol,
  }) async {
    try {
      // Crear usuario en Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      final usuario = UserModel(
        uid: uid,
        nombre: nombre,
        apellidos: apellidos,
        telefono: telefono,
        direccion: direccion,
        email: email,
        username: username,
        rol: rol,
      );

      // Guardar en colección 'usuarios'
      await _firestore.collection('usuario').doc(uid).set(usuario.toMap());
      
    } catch (e) {
      return e.toString();
    }
    return null;
  }
}