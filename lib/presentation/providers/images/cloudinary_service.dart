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
      final response = await request.send();
      onProgress?.call(0.9);
      
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = json.decode(responseData);
        
        onProgress?.call(1.0);
        
        return jsonData['secure_url'];
      } else {
        await response.stream.bytesToString();
        return null;
      }
      
    } catch (e) {
      return null;
    }
  }
  
  // Método con validación de parámetros
  static String getOptimizedImageUrl(
    String originalUrl, {
    int? width,
    int? height,
    String quality = 'auto:good',
    String format = 'auto',
  }) {
    try {
      // Validar que la URL sea de Cloudinary
      if (!originalUrl.contains('cloudinary.com')) {
        return originalUrl;
      }

      // Validar dimensiones
      if (width != null && (width <= 0 || width > 4000)) {
        width = null;
      }
      
      if (height != null && (height <= 0 || height > 4000)) {
        height = null;
      }

      // Si no hay transformaciones válidas, retornar URL original
      if (width == null && height == null) {
        return originalUrl;
      }

      // Extraer public_id de la URL
      final uri = Uri.parse(originalUrl);
      final segments = uri.pathSegments;
      
      final uploadIndex = segments.indexOf('upload');
      
      if (uploadIndex == -1) {
        return originalUrl;
      }
      
      final publicId = segments.sublist(uploadIndex + 1).join('/');
      final publicIdWithoutExtension = publicId.split('.').first;
      
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
      
      final finalUrl = 'https://res.cloudinary.com/$cloudName/image/upload/$transformationString/$publicIdWithoutExtension';
      
      return finalUrl;
    } catch (e) {
      return originalUrl;
    }
  }
}
