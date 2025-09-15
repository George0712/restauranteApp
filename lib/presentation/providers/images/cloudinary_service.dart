// services/cloudinary_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'dxsvu1icx';
  static const String uploadPreset = 'flutter_products';
  
  static Future<String?> uploadImage(
    File imageFile, {
    Function(double)? onProgress,
  }) async {
    try {
      print('=== SUBIENDO A CLOUDINARY ===');
      print('Cloud Name: $cloudName');
      print('Upload Preset: $uploadPreset');
      print('Archivo: ${imageFile.path}');

      onProgress?.call(0.1);
      
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      
      onProgress?.call(0.3);
      
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = 'products';
      
      onProgress?.call(0.5);
      
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path)
      );
      
      onProgress?.call(0.7);

      print('Enviando request...');
      
      final response = await request.send();
      
      onProgress?.call(0.9);

       print('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = json.decode(responseData);
        
        print('Upload successful: ${jsonData['secure_url']}');
        onProgress?.call(1.0);
        
        return jsonData['secure_url'];
      } else {
        print('Error en Cloudinary: ${response.statusCode}');
        final errorData = await response.stream.bytesToString();
        print('Error details: $errorData');
        return null;
      }
      
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }
  
  // Método mejorado con validación de parámetros
  static String getOptimizedImageUrl(
    String originalUrl, {
    int? width,
    int? height,
    String quality = 'auto:good',
    String format = 'auto',
  }) {
    try {
      print('=== OPTIMIZANDO URL ===');
      print('URL original: $originalUrl');
      print('Dimensiones solicitadas - W: $width, H: $height');
      // Validar que la URL sea de Cloudinary
      if (!originalUrl.contains('cloudinary.com')) {
        print('No es URL de Cloudinary, retornando original');
        return originalUrl;
      }

      // Validar dimensiones
      if (width != null && (width <= 0 || width > 4000)) {
        print('Width inválido: $width, ignorando');
        width = null;
      }
      
      if (height != null && (height <= 0 || height > 4000)) {
        print('Height inválido: $height, ignorando');
        height = null;
      }

      // Si no hay transformaciones válidas, retornar URL original
      if (width == null && height == null) {
        print('No hay dimensiones válidas, retornando URL original');
        return originalUrl;
      }

      // Extraer public_id de la URL
      final uri = Uri.parse(originalUrl);
      final segments = uri.pathSegments;
      print('Segmentos de URL: $segments');
      
      final uploadIndex = segments.indexOf('upload');
      
      if (uploadIndex == -1) {
        print('No se encontró "upload" en la URL, retornando original');
        return originalUrl;
      }
      
      final publicId = segments.sublist(uploadIndex + 1).join('/');
      final publicIdWithoutExtension = publicId.split('.').first;
      print('Public ID: $publicIdWithoutExtension');
      
      // Construir transformaciones
      List<String> transformations = [];
      
      if (width != null || height != null) {
        String resize = 'c_fill';
        if (width != null) resize += ',w_$width';
        if (height != null) resize += ',h_$height';
        transformations.add(resize);
      }
      
      transformations.add('q_$quality');
      transformations.add('f_$format');
      
      final transformationString = transformations.join(',');
      print('Transformaciones: $transformationString');
      
      final finalUrl = 'https://res.cloudinary.com/$cloudName/image/upload/$transformationString/$publicIdWithoutExtension';
      print('URL final: $finalUrl');
      
      return finalUrl;
      
    } catch (e) {
      print('❌ Error in getOptimizedImageUrl: $e');
      return originalUrl;
    }
  }
}
