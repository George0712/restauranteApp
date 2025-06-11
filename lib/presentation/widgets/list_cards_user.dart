import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/data/models/user_model.dart';
import 'package:restaurante_app/presentation/providers/admin/admin_provider.dart';

class ListCardsUsers extends ConsumerWidget {
  final AsyncValue<List<UserModel>> usersAsync;
  final String rol;

  const ListCardsUsers({Key? key, required this.usersAsync, required this.rol}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuariosAsync = ref.watch(usersProvider(rol));
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return usuariosAsync.when(
      data: (usuarios) {
        if (usuarios.isEmpty) {
          return Text('No hay usuarios con rol "$rol" registrados.');
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: usuarios.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet
                    ? 4
                    : 2, // 2 columnas
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1, // cuadrado
          ),
          itemBuilder: (context, index) {
            final usuario = usuarios[index];

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Center(
                    child: Icon(
                      Icons.person, 
                      size: 60, 
                      color: theme.primaryColor.withAlpha(230),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${usuario.nombre} ${usuario.apellidos}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Text('Error al cargar usuarios: $error'),
    );
  }
}