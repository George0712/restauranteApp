// widgets/cloudinary_image_widget.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:restaurante_app/presentation/providers/images/cloudinary_service.dart';

class CloudinaryImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const CloudinaryImageWidget({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget fallbackWidget = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withValues(alpha: 0.1),
            theme.primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: borderRadius,
      ),
      child: const Icon(
        Icons.fastfood_rounded,
        size: 80,
        color: Colors.grey,
      ),
    );

    if (imageUrl == null || imageUrl!.isEmpty) {
      return fallbackWidget;
    }

    // Generar URL optimizada
    final optimizedUrl = _getValidOptimizedUrl(imageUrl!);

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: optimizedUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: borderRadius,
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorWidget: (context, url, error) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: borderRadius,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(height: 4),
                Text(
                  'Error',
                  style: TextStyle(fontSize: 12, color: Colors.red[800]),
                ),
              ],
            ),
          );
        },
        // Agregar callback para éxito
        imageBuilder: (context, imageProvider) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              image: DecorationImage(
                image: imageProvider,
                fit: fit,
              ),
            ),
          );
        },
      ),
    );
  }

  String _getValidOptimizedUrl(String originalUrl) {
    try {
      // Validar dimensiones
      int? validWidth;
      int? validHeight;

      if (width != null && width!.isFinite && width! > 0) {
        validWidth = width!.toInt();
      }

      if (height != null && height!.isFinite && height! > 0) {
        validHeight = height!.toInt();
      }

      // Si no hay dimensiones válidas, usar la URL original
      if (validWidth == null && validHeight == null) {
        return originalUrl;
      }

      final optimizedUrl = CloudinaryService.getOptimizedImageUrl(
        originalUrl,
        width: validWidth,
        height: validHeight,
        quality: 'auto:good',
        format: 'auto',
      );
      
      return optimizedUrl;
      
    } catch (e) {
      return originalUrl;
    }
  }
}