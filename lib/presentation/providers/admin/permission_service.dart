// services/permission_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';

class PermissionService {
  static Future<bool> requestGalleryPermission(BuildContext? context) async {
    Permission permission;
    
    // Determinar el permiso según la versión de Android
    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      if (deviceInfo.version.sdkInt >= 33) {
        permission = Permission.photos; // Android 13+
      } else if (deviceInfo.version.sdkInt >= 30) {
        permission = Permission.storage; // Android 11-12
      } else {
        permission = Permission.storage; // Android < 11
      }
    } else {
      permission = Permission.photos; // iOS
    }
    
    // Verificar estado actual
    var status = await permission.status;
    
    // Si ya está concedido, retornar true
    if (status.isGranted) {
      return true;
    }
    
    // Si tiene acceso limitado (Android 14+)
    if (status.isLimited) {
      return true; // Acceso parcial es suficiente
    }
    
    // Si está permanentemente denegado, mostrar diálogo y abrir configuración
    if (status.isPermanentlyDenied) {
      return context != null && context.mounted ? await _handlePermanentlyDenied(context) : false;
    }
    
    // Si está restringido (por controles parentales)
    if (status.isRestricted) {
      if (context != null) {
        SnackbarHelper.showWarning('Acceso a galería restringido por el sistema');
      }
      return false;
    }
    
    // Explicar por qué necesitamos el permiso antes de solicitarlo
    if (context != null && context.mounted) {
      final shouldRequest = await _showPermissionRationale(context);
      if (!shouldRequest) {
        return false;
      }
    }
    
    // Solicitar permiso
    status = await permission.request();
    
    // Manejar la respuesta
    if (status.isGranted || status.isLimited) {
      return true;
    } else if (status.isPermanentlyDenied) {
      return context != null && context.mounted ? await _handlePermanentlyDenied(context) : false;
    } else {
      if (context != null) {
        SnackbarHelper.showError('Permiso de galería denegado');
      }
      return false;
    }
  }
  
  static Future<bool> requestCameraPermission(BuildContext? context) async {
    const permission = Permission.camera;
    
    var status = await permission.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isPermanentlyDenied) {
      return context != null && context.mounted ? await _handlePermanentlyDenied(context, isCamera: true) : false;
    }
    
    if (status.isRestricted) {
      if (context != null) {
        SnackbarHelper.showWarning('Acceso a cámara restringido por el sistema');
      }
      return false;
    }
    
    // Explicar por qué necesitamos el permiso
    if (context != null && context.mounted) {
      final shouldRequest = await _showCameraPermissionRationale(context);
      if (!shouldRequest) {
        return false;
      }
    }
    
    status = await permission.request();
    
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      return context != null && context.mounted ? await _handlePermanentlyDenied(context, isCamera: true) : false;
    } else {
      if (context != null) {
        SnackbarHelper.showError('Permiso de cámara denegado');
      }
      return false;
    }
  }
  
  static Future<bool> _handlePermanentlyDenied(BuildContext? context, {bool isCamera = false}) async {
    if (context == null || !context.mounted) return false;
    
    final permissionName = isCamera ? 'cámara' : 'galería';
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text('Permiso de $permissionName requerido'),
        content: Text(
          'Para seleccionar imágenes de productos, necesitas habilitar el acceso a $permissionName en la configuración de la aplicación.\n\n'
          '¿Deseas abrir la configuración ahora?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop(true);
              final opened = await openAppSettings();
              if (opened) {
                // Opcional: Mostrar mensaje de que revise cuando regrese
                SnackbarHelper.showInfo('Habilita el permiso de $permissionName y regresa a la aplicación');
              }
            },
            child: const Text('Abrir Configuración'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  static Future<bool> _showPermissionRationale(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Acceso a Galería'),
        content: const Text(
          'Para agregar imágenes a tus productos, necesitamos acceso a tu galería de fotos.\n\n'
          'Esto nos permitirá que selecciones las mejores imágenes para mostrar tus productos.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('No Permitir'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Permitir'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  static Future<bool> _showCameraPermissionRationale(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Acceso a Cámara'),
        content: const Text(
          'Para tomar fotos de tus productos directamente, necesitamos acceso a tu cámara.\n\n'
          'Esto te permitirá capturar imágenes de alta calidad al instante.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('No Permitir'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Permitir'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  static Future<void> showImageSourceDialog(
    BuildContext context, 
    Function(bool fromCamera) onSourceSelected
  ) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bottomSheetContext) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Seleccionar imagen de producto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Galería'),
              subtitle: const Text('Seleccionar desde galería de fotos'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                onSourceSelected(false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Cámara'),
              subtitle: const Text('Tomar foto con la cámara'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                onSourceSelected(true);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
