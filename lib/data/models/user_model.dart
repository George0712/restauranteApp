class UserModel {
  final String uid;
  final String nombre;
  final String apellidos;
  final String telefono;
  final String direccion;
  final String email;
  final String username;
  final String rol;
  final String? foto;

  UserModel(
      {required this.uid,
      required this.nombre,
      required this.apellidos,
      required this.telefono,
      required this.direccion,
      required this.email,
      required this.username,
      required this.rol,
      this.foto});

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nombre': nombre,
      'apellidos': apellidos,
      'telefono': telefono,
      'direccion': direccion,
      if(foto != null) 'foto': foto,
      'email': email,
      'username': username,
      'rol': rol,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      nombre: map['nombre'] ?? '',
      apellidos: map['apellidos'] ?? '',
      telefono: map['telefono'] ?? '',
      direccion: map['direccion'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      rol: map['rol'] ?? '',
      foto: map['foto'], 
    );
  }

  UserModel copyWith({
    String? uid,
    String? nombre,
    String? apellidos,
    String? telefono,
    String? direccion,
    String? email,
    String? username,
    String? rol,
    String? foto,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      nombre: nombre ?? this.nombre,
      apellidos: apellidos ?? this.apellidos,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      email: email ?? this.email,
      username: username ?? this.username,
      rol: rol ?? this.rol,
      foto: foto ?? this.foto,
    );
  }
}
